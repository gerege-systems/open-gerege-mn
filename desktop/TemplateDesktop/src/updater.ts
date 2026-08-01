// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Авто-шинэчлэлт. Апп өөрөө сувгаа шалгаж, шинэ хувилбар гарсныг таниад
// АРЫН ДЭВСГЭРТ татаж, дуусахад хэрэглэгчээс асууж дахин эхэлнэ.
//
// Яагаад асуудаг вэ: татаж дуусах мөчид хэрэглэгч маягт бөглөж, AI-тай ярьж
// байж болно — тэр хором аппыг чимээгүй хаах нь өгөгдөл алдана. Асуулгын
// анхдагч товч нь «Одоо дахин эхлүүлэх», «Дараа» сонговол `autoInstallOnAppQuit`
// дараагийн удаа хаахад нь өөрөө суулгана. Аль ч тохиолдолд хэрэглэгч гараар
// татаж, суулгах шаардлагагүй.

import { app, dialog } from 'electron';
import { autoUpdater, type ProgressInfo, type UpdateInfo } from 'electron-updater';
import {
  resolveFeedURL,
  UPDATE_CHECK_INTERVAL_MS,
  UPDATE_FIRST_CHECK_DELAY_MS,
} from './config';
import { readState, writeState } from './store';
import {
  describeUpdateError,
  isNewerVersion,
  shouldAutoCheck,
  updateMenuEnabled as menuEnabled,
  updateMenuLabel as menuLabel,
  type UpdateStatus,
} from './update';
import { activeAppWindow } from './windows';

let status: UpdateStatus = { phase: 'idle' };
let statusListener: (() => void) | null = null;

/** Хэрэглэгч өөрөө цэсээр эхлүүлсэн шалгалт уу — тайлагналт үүнээс хамаарна. */
let manualCheck = false;

/** Дахин эхлүүлэх асуулга нэг хувилбарт зөвхөн нэг удаа гарна. */
let promptedVersion: string | null = null;

let timer: ReturnType<typeof setInterval> | null = null;

/** Цэс төлөв бүрд шинэчлэгдэхийн тулд main.ts энд `buildMenu`-г холбоно. */
export function onUpdateStatusChange(listener: () => void): void {
  statusListener = listener;
}

function setStatus(next: UpdateStatus): void {
  status = next;
  statusListener?.();
}

/** Цэсний шошго / идэвх — menu.ts зөвхөн эдгээрийг мэднэ. */
export function updateMenuLabel(): string {
  return menuLabel(status);
}

export function updateMenuEnabled(): boolean {
  return menuEnabled(status);
}

/**
 * Багцлагдсан апп уу. Хөгжүүлэлтийн (`npm start`) горимд Squirrel/сувгийн
 * бүтэц байхгүй тул шалгалт утгагүй — `GEREGE_UPDATE_DEV=1` -ээр албадаж
 * болно (`dev-app-update.yml` шаардана).
 */
function updatesSupported(): boolean {
  return app.isPackaged || process.env.GEREGE_UPDATE_DEV === '1';
}

export function initUpdater(): void {
  // Хөгжүүлэлтийн горимд шалгалт/таймер ажиллуулахгүй. Цэсний зүйл нээлттэй
  // хэвээр — дарвал яагаад боломжгүйг тайлбарлана (`checkForUpdates`).
  if (!updatesSupported()) return;

  autoUpdater.setFeedURL({ provider: 'generic', url: resolveFeedURL(process.env.GEREGE_UPDATE_URL) });
  // Татахаас ӨМНӨ хувилбарыг өөрсдөө шалгана (доорх `update-available`) —
  // тиймээс автоматаар татахыг унтрааж, өөрсдөө эхлүүлнэ.
  autoUpdater.autoDownload = false;
  // Хэрэглэгч «Дараа» гэвэл аппыг хаахад чимээгүй суулгана.
  autoUpdater.autoInstallOnAppQuit = true;
  if (process.env.GEREGE_UPDATE_DEV === '1') autoUpdater.forceDevUpdateConfig = true;

  registerEvents();

  const now = Date.now();
  if (shouldAutoCheck(now, readState().lastUpdateCheck, UPDATE_CHECK_INTERVAL_MS)) {
    setTimeout(() => void checkForUpdates(false), UPDATE_FIRST_CHECK_DELAY_MS);
  }

  // Апп удаан нээлттэй байхад ч шинэ хувилбарыг барина.
  timer = setInterval(() => void checkForUpdates(false), UPDATE_CHECK_INTERVAL_MS);
  app.once('before-quit', () => {
    if (timer) clearInterval(timer);
  });
}

function registerEvents(): void {
  autoUpdater.on('checking-for-update', () => {
    setStatus({ phase: 'checking' });
  });

  autoUpdater.on('update-available', (info: UpdateInfo) => {
    // Буруу тохируулсан суваг ХУУЧИН багц санал болговол татахгүй.
    if (!isNewerVersion(info.version, app.getVersion())) {
      setStatus({ phase: 'idle' });
      if (manualCheck) void showUpToDate();
      return;
    }
    setStatus({ phase: 'downloading', version: info.version });
    void autoUpdater.downloadUpdate().catch(() => {
      // Алдаа `error` эвентээр давхар ирнэ — энд зөвхөн promise-ыг барина.
    });
  });

  autoUpdater.on('update-not-available', () => {
    setStatus({ phase: 'idle' });
    if (manualCheck) void showUpToDate();
  });

  autoUpdater.on('download-progress', (progress: ProgressInfo) => {
    setStatus({ phase: 'downloading', version: status.version, percent: progress.percent });
  });

  autoUpdater.on('update-downloaded', (info: UpdateInfo) => {
    setStatus({ phase: 'ready', version: info.version });
    void promptRestart(info.version);
  });

  autoUpdater.on('error', (err: Error) => {
    setStatus({ phase: 'error' });
    if (!manualCheck) return;
    const message = err?.message ?? String(err);
    void showDialog({
      type: 'error',
      title: 'Шинэчлэлт',
      message: describeUpdateError(message),
      detail: message,
      buttons: ['Хаах'],
    });
  });
}

/** Цэсний «Шинэчлэлт шалгах…» болон авто давтамжийн нэгдсэн орц. */
export async function checkForUpdates(manual: boolean): Promise<void> {
  if (!updatesSupported()) {
    if (manual) {
      await showDialog({
        type: 'info',
        title: 'Шинэчлэлт',
        message: 'Хөгжүүлэлтийн горимд авто-шинэчлэлт ажиллахгүй.',
        detail: 'Багцалсан (npm run dist:mac) аппад шинэчлэлт автоматаар шалгагдана.',
        buttons: ['Ойлголоо'],
      });
    }
    return;
  }

  // Аль хэдийн татсан бол дахин шалгах хэрэггүй — шууд дахин эхлэхийг санална.
  if (status.phase === 'ready') {
    promptedVersion = null;
    await promptRestart(status.version);
    return;
  }
  if (status.phase === 'checking' || status.phase === 'downloading') return;

  manualCheck = manual;
  writeState({ lastUpdateCheck: Date.now() });
  try {
    await autoUpdater.checkForUpdates();
  } catch {
    // `error` эвент аль хэдийн тайлагнасан.
  }
}

async function showUpToDate(): Promise<void> {
  await showDialog({
    type: 'info',
    title: 'Шинэчлэлт',
    message: 'Та хамгийн сүүлийн хувилбарыг ашиглаж байна.',
    detail: `${app.getName()} ${app.getVersion()}`,
    buttons: ['Ойлголоо'],
  });
}

async function promptRestart(version: string | undefined): Promise<void> {
  const tag = version ?? '';
  if (promptedVersion === tag) return;
  promptedVersion = tag;

  const { response } = await showDialog({
    type: 'info',
    title: 'Шинэчлэлт бэлэн боллоо',
    message: version ? `${app.getName()} ${version} татагдлаа.` : 'Шинэ хувилбар татагдлаа.',
    detail:
      'Апп дахин эхэлснээр шинэ хувилбар идэвхжинэ. «Дараа» сонговол аппыг дараагийн удаа хаахад автоматаар суулгана.',
    buttons: ['Одоо дахин эхлүүлэх', 'Дараа'],
    defaultId: 0,
    cancelId: 1,
  });

  if (response === 0) restartAndInstall();
}

/**
 * Суулгаад дахин эхлүүлнэ. `quitAndInstall`-ыг эвентийн гогцооноос ГАДНА
 * дуудна — dialog-ийн callback дотроос шууд дуудвал macOS дээр цонх хаагдахгүй
 * гацах тохиолдол бий.
 */
function restartAndInstall(): void {
  setImmediate(() => autoUpdater.quitAndInstall(false, true));
}

/**
 * Асуулгыг идэвхтэй аппын цонхонд бэхэлж харуулна (macOS дээр sheet болно).
 * Цонх байхгүй бол (бүх цонх хаагдсан, апп Dock-д үлдсэн) бие даасан цонхоор.
 */
function showDialog(options: Electron.MessageBoxOptions): Promise<Electron.MessageBoxReturnValue> {
  const win = activeAppWindow();
  return win ? dialog.showMessageBox(win, options) : dialog.showMessageBox(options);
}
