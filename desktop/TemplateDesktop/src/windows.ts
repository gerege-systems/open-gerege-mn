// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Цонх үүсгэх, шилжилтийн бодлогыг хэрэгжүүлэх давхарга.

import { BrowserWindow, shell, screen, type WebContents } from 'electron';
import path from 'node:path';
import { classifyURL } from './policy';
import { readState, writeState } from './store';

const DEFAULT_WIDTH = 1440;
const DEFAULT_HEIGHT = 900;
// Web апп нь responsive тул нарийн өргөнд мобайл layout руу шилжинэ —
// доод хязгаарыг зориуд бага байлгав.
const MIN_WIDTH = 420;
const MIN_HEIGHT = 560;

const STATIC_DIR = path.join(__dirname, '..', 'static');
const PRELOAD = path.join(__dirname, 'preload.js');

const isMac = process.platform === 'darwin';

/**
 * Цонхны дүрс. macOS дээр дүрс нь багцаас (.icns) ирдэг тул тогтоох
 * шаардлагагүй — харин Windows/Linux дээр тогтоохгүй бол taskbar-т Electron-ы
 * үндсэн дүрс харагдана (ялангуяа багцлаагүй, хөгжүүлэлтийн горимд).
 */
const WINDOW_ICON = isMac ? undefined : path.join(__dirname, '..', 'resources', 'icon.png');

/**
 * Гарчгийн мөрийг цонхны хүрээнд шингээх (macOS `hiddenInset`) — аппын өөрийн
 * topbar нь гарчгийн мөрийн үүргийг гүйцэтгэнэ. Windows/Linux дээр стандарт
 * хүрээ ЗОРИУД хэвээр: тэдгээр платформ дээр цонхны удирдлагын байрлал,
 * дараалал нь орчны сэдэвээс (Windows 11 snap, GNOME/KDE) хамаардаг тул
 * өөрсдөө зурвал жижиг зөрүү бүр эвдрэл шиг харагдана.
 */
export function usesOverlayTitleBar(): boolean {
  return isMac;
}

/**
 * Гэрлэн товчнуудад (traffic lights) зүүн дээд буланд чөлөөлөх өргөн.
 * Гурван товч 3×14px + хооронд нь 20px + захын зай ≈ 78px.
 */
export const TITLEBAR_INSET = 78;

/** Товчнуудыг 64px topbar-ийн голд байрлуулна ((64 − 16) / 2 = 24). */
const TRAFFIC_LIGHT_POSITION = { x: 18, y: 24 };

/**
 * Бүтэн дэлгэц (native fullscreen) үед гэрлэн товчнууд алга болно — web тал
 * үүнийг мэдэх аргагүй (macOS-ийн fullscreen нь Fullscreen API-г өдөөдөггүй).
 * Тиймээс нөөцөлсөн зайг бүрхүүл өөрөө дарж бичнэ. Энэ нь ЗӨВХӨН загвар —
 * алсын агуулгад ямар ч чадвар нээхгүй.
 */
const FULLSCREEN_CSS = `
  html[data-titlebar="overlay"] { --titlebar-inset: 0px !important; }
  html[data-titlebar="overlay"] .iconrail__brand img { visibility: visible !important; }
`;

/** Ачаалж буй серверийн origin — шилжилтийн бодлогын гол хэмжүүр. */
let appOrigin = '';

/** Туслах (тохиргооны) цонхнуудын webContents id — аппын цонхноос ялгахад. */
const helperContents = new Set<number>();

export function setAppOrigin(origin: string): void {
  appOrigin = origin;
}

export function getAppOrigin(): string {
  return appOrigin;
}

/** Аппын цонхнууд (туслах цонхыг оруулахгүй). */
export function appWindows(): BrowserWindow[] {
  return BrowserWindow.getAllWindows().filter((w) => !helperContents.has(w.webContents.id));
}

/** Фокустай аппын цонх, эс бөгөөс хамгийн сүүлийнх. */
export function activeAppWindow(): BrowserWindow | null {
  const focused = BrowserWindow.getFocusedWindow();
  if (focused && !helperContents.has(focused.webContents.id)) return focused;
  const windows = appWindows();
  return windows[windows.length - 1] ?? null;
}

/** Хуудсын түүхээр ухрах (боломжтой бол). */
export function goBack(win: BrowserWindow): void {
  if (win.webContents.navigationHistory.canGoBack()) win.webContents.navigationHistory.goBack();
}

/** Хуудсын түүхээр урагшлах (боломжтой бол). */
export function goForward(win: BrowserWindow): void {
  if (win.webContents.navigationHistory.canGoForward()) win.webContents.navigationHistory.goForward();
}

/**
 * Шилжилт, цонх нээх, эрхийн бодлогыг тухайн webContents дээр тогтооно.
 * Гадаад холбоос системийн хөтчөөр нээгдэнэ — аппын cookie сав хамгаалагдана.
 */
export function attachNavigationPolicy(contents: WebContents): void {
  contents.on('will-navigate', (event, url) => {
    const decision = classifyURL(url, appOrigin);
    if (decision === 'allow') return;
    event.preventDefault();
    if (decision === 'external') void openExternal(url);
  });

  contents.setWindowOpenHandler(({ url }) => {
    const decision = classifyURL(url, appOrigin);
    if (decision === 'allow') {
      return {
        action: 'allow',
        overrideBrowserWindowOptions: {
          minWidth: MIN_WIDTH,
          minHeight: MIN_HEIGHT,
          webPreferences: baseWebPreferences(),
        },
      };
    }
    if (decision === 'external') void openExternal(url);
    return { action: 'deny' };
  });

  // <webview> ашигладаггүй — оролдлого бүрийг таслана.
  contents.on('will-attach-webview', (event) => {
    event.preventDefault();
  });

  // Ачаалж чадаагүй үед офлайн хуудас руу (тасалдсан хүсэлтийг тооцохгүй).
  contents.on('did-fail-load', (_event, errorCode, errorDescription, validatedURL, isMainFrame) => {
    if (!isMainFrame) return;
    if (errorCode === -3) return; // ERR_ABORTED — хэрэглэгч өөрөө тасалсан
    if (validatedURL.startsWith('file://')) return;
    const win = BrowserWindow.fromWebContents(contents);
    if (win) showOffline(win, errorDescription || String(errorCode));
  });
}

async function openExternal(url: string): Promise<void> {
  try {
    await shell.openExternal(url);
  } catch {
    // Схемийг зохицуулах апп байхгүй байж болно (жишээ нь geregesmartid://) —
    // энэ нь алдаа биш, чимээгүй алгасна.
  }
}

function baseWebPreferences(): Electron.WebPreferences {
  return {
    preload: PRELOAD,
    contextIsolation: true,
    nodeIntegration: false,
    sandbox: true,
    webviewTag: false,
    // Монгол хэлний толь байхгүй тул spellcheck-ийг унтраав (толь татахгүй).
    spellcheck: false,
  };
}

/** Дэлгэцийн ажлын талбайд багтаах — өмнөх дэлгэц салсан байж болно. */
function fitToScreen(bounds: { x?: number; y?: number; width: number; height: number }) {
  const area = screen.getDisplayMatching({
    x: bounds.x ?? 0,
    y: bounds.y ?? 0,
    width: bounds.width,
    height: bounds.height,
  }).workArea;

  const width = Math.min(bounds.width, area.width);
  const height = Math.min(bounds.height, area.height);
  const x = bounds.x === undefined ? undefined : Math.min(Math.max(bounds.x, area.x), area.x + area.width - width);
  const y = bounds.y === undefined ? undefined : Math.min(Math.max(bounds.y, area.y), area.y + area.height - height);
  return { x, y, width, height };
}

export function createMainWindow(url: string): BrowserWindow {
  const state = readState();
  const saved = state.bounds ?? { width: DEFAULT_WIDTH, height: DEFAULT_HEIGHT };
  const bounds = fitToScreen(saved);

  const win = new BrowserWindow({
    ...bounds,
    minWidth: MIN_WIDTH,
    minHeight: MIN_HEIGHT,
    show: false,
    title: 'Gerege Template',
    icon: WINDOW_ICON,
    // Хуудасны өнгө ачаалагдах хүртэл цагаан анивчихаас сэргийлнэ.
    backgroundColor: '#0b1220',
    // macOS: гарчгийн мөргүй, гэрлэн товчнууд аппын topbar дотор суух —
    // web тал `html[data-titlebar="overlay"]`-аар зүүн зайг нөөцөлж, topbar-ыг
    // чирэх бүс болгоно (`frontend/src/app/globals.css`).
    ...(isMac
      ? { titleBarStyle: 'hiddenInset' as const, trafficLightPosition: TRAFFIC_LIGHT_POSITION }
      : {}),
    webPreferences: baseWebPreferences(),
  });

  if (state.maximized) win.maximize();

  win.once('ready-to-show', () => win.show());

  if (isMac) attachFullScreenStyle(win);

  // Хоёр хуруутай зөөлт — хуудас ухрах / урагшлах. `swipe` бол зөвхөн macOS-ийн
  // үйл явдал; Windows/Linux дээр хулганы 4/5-р товч энэ үүргийг гүйцэтгэдэг тул
  // тэдгээрийг `app-command`-аар тусад нь холбоно.
  if (isMac) {
    win.on('swipe', (_event, direction) => {
      if (direction === 'left') goBack(win);
      else if (direction === 'right') goForward(win);
    });
  } else {
    win.on('app-command', (_event, command) => {
      if (command === 'browser-backward') goBack(win);
      else if (command === 'browser-forward') goForward(win);
    });
  }

  const persistBounds = () => {
    if (win.isDestroyed() || win.isMinimized() || win.isFullScreen()) return;
    writeState({ maximized: win.isMaximized(), ...(win.isMaximized() ? {} : { bounds: win.getNormalBounds() }) });
  };
  win.on('resize', persistBounds);
  win.on('move', persistBounds);
  win.on('close', persistBounds);

  // attachNavigationPolicy-г main.ts дэх `web-contents-created` тогтоодог —
  // энд давхар холбовол гадаад холбоос хоёр удаа нээгдэнэ.
  void win.loadURL(url);
  return win;
}

/**
 * Бүтэн дэлгэцэд орох/гарахад гарчгийн мөрийн зайг залруулах загварыг тавьж/авна.
 * Шилжилт бүрд оруулсан CSS цэвэрлэгддэг тул хуудас ачаалагдах бүрд дахин тавина.
 */
function attachFullScreenStyle(win: BrowserWindow): void {
  let key: string | null = null;

  const apply = async () => {
    if (key !== null) return;
    try {
      key = await win.webContents.insertCSS(FULLSCREEN_CSS);
    } catch {
      // Цонх хаагдсан байж болно — загварын засвар тул чимээгүй алгасна.
    }
  };

  const clear = async () => {
    if (key === null) return;
    const current = key;
    key = null;
    try {
      await win.webContents.removeInsertedCSS(current);
    } catch {
      // Дээрхтэй ижил.
    }
  };

  win.on('enter-full-screen', () => void apply());
  win.on('leave-full-screen', () => void clear());
  win.webContents.on('did-finish-load', () => {
    key = null; // Шилжилт нь өмнөх түлхүүрийг хүчингүй болгосон.
    if (win.isFullScreen()) void apply();
  });
}

/**
 * Сүлжээ тасарсан / сервер хүрэхгүй үеийн дотоод хуудас. Цонх аппын цонх хэвээр
 * үлдэнэ — "Дахин оролдох" дарахад мөн энэ цонхон дотор апп сэргэнэ.
 *
 * Тэмдэглэл: офлайн хуудсанд preload-internal ачаалагдана — цонх үүсэх үедээ
 * тогтоогддог тул main процесс IPC-г илгээгчийн file:// хаягаар шалгана.
 */
export function showOffline(win: BrowserWindow, reason: string): void {
  void win.loadFile(path.join(STATIC_DIR, 'offline.html'), {
    // `overlay` — гарчгийн мөр цонхонд шингэсэн эсэх. Хуудас өөрөө платформоо
    // мэдэх аргагүй (file:// хуудсанд зөвхөн geregeShell гүүр нээгддэг) тул
    // чирэх бүс хэрэгтэй эсэхийг main процесс хэлж өгнө.
    query: { origin: appOrigin, reason, overlay: usesOverlayTitleBar() ? '1' : '0' },
  });
}

/** Офлайн хуудаснаас гарч жинхэнэ апп руу буцна. */
export function reloadApp(win: BrowserWindow): void {
  void win.loadURL(appOrigin);
}

let serverWindow: BrowserWindow | null = null;

/** "Сервер солих…" — жижиг дотоод тохиргооны цонх. */
export function openServerWindow(parent: BrowserWindow | null): BrowserWindow {
  if (serverWindow && !serverWindow.isDestroyed()) {
    serverWindow.focus();
    return serverWindow;
  }

  const win = new BrowserWindow({
    width: 520,
    height: 420,
    resizable: false,
    minimizable: false,
    maximizable: false,
    title: 'Сервер солих',
    parent: parent ?? undefined,
    modal: false,
    show: false,
    backgroundColor: '#0b1220',
    webPreferences: baseWebPreferences(),
  });

  helperContents.add(win.webContents.id);
  win.once('ready-to-show', () => win.show());
  win.on('closed', () => {
    serverWindow = null;
  });

  void win.loadFile(path.join(STATIC_DIR, 'server.html'));
  serverWindow = win;
  return win;
}

/** Аппын дотор замаар шилжинэ (цэсний хурдан холбоосууд). */
export function navigateTo(routePath: string): void {
  const win = activeAppWindow() ?? createMainWindow(appOrigin);
  void win.loadURL(new URL(routePath, appOrigin).toString());
  win.focus();
}

/** Бүх аппын цонхыг (шинэ) сервер рүү шилжүүлнэ. */
export function reloadAllWindows(): void {
  const windows = appWindows();
  if (windows.length === 0) {
    createMainWindow(appOrigin);
    return;
  }
  for (const win of windows) void win.loadURL(appOrigin);
}
