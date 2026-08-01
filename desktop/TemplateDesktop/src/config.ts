// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Аппын тохиргоо. Энэ файл electron-оос хамаарахгүй — цэвэр функцууд тул
// `node --test`-ээр шууд шалгагдана.

/**
 * Үйлдвэрлэлийн жишиг deployment — ЭНЭ репогийнх.
 *
 * `template.gerege.mn` (public бус) руу заавал болохгүй: тэр нь өөр репогийн
 * (`template-gerege-mn`) deployment бөгөөд desktop давхаргыг (preload →
 * theme-bootstrap → `html[data-desktop]`) агуулаагүй тул апп нь хөтөч дээрхтэй
 * ялгаагүй харагдана.
 */
export const DEFAULT_APP_URL = 'https://public.template.gerege.mn';

/** Локал хөгжүүлэлт — `npm run dev` (frontend/) 3000 порт дээр өргөнө. */
export const DEV_APP_URL = 'http://localhost:3000';

/** "Сервер солих" цонхонд харагдах бэлэн сонголтууд. */
export const SERVER_PRESETS: ReadonlyArray<{ label: string; url: string }> = [
  { label: 'Үйлдвэрлэл — public.template.gerege.mn', url: DEFAULT_APP_URL },
  { label: 'Локал хөгжүүлэлт — localhost:3000', url: DEV_APP_URL },
];

/**
 * Нэвтрэлт / интеграцийн урсгалд цонхон дотор шилжихийг зөвшөөрөх хостууд.
 *
 * Эдгээр урсгал нь аппын cookie сав (session) дээр тулгуурладаг тул системийн
 * хөтчид гаргаж болохгүй: OAuth callback нь эргээд аппын origin дээр cookie
 * бичдэг. Цэгээр эхэлсэн загвар нь дэд домэйныг бүхэлд нь хамарна.
 *
 *  - `.gerege.mn`      — Gerege SSO (sso.gerege.mn) ба бусад дотоод үйлчилгээ
 *  - `eidmongolia.mn`  — eID Mongolia Smart-ID баталгаажуулалт
 *  - `accounts.google.com` — Google нэвтрэлт / Drive · Meet интеграцийн зөвшөөрөл
 *  - `.dropbox.com`    — Dropbox интеграцийн зөвшөөрөл
 */
export const AUTH_HOSTS: readonly string[] = [
  '.gerege.mn',
  'gerege.mn',
  'eidmongolia.mn',
  '.eidmongolia.mn',
  'accounts.google.com',
  'accounts.youtube.com',
  'dropbox.com',
  '.dropbox.com',
];

/** Аппын origin дээр л зөвшөөрөгдөх хөтчийн эрхүүд. */
export const ALLOWED_PERMISSIONS: readonly string[] = [
  'media', // микрофон — AI чат, дуут мессеж, амьд орчуулга (камер тусад нь хаагдана)
  'clipboard-sanitized-write',
  'notifications',
  'fullscreen',
];

/**
 * Авто-шинэчлэлтийн суваг. `electron-builder.yml` дахь `publish.url`-тэй ЯГ ижил
 * байх ёстой — тэндээс `latest-mac.yml` / `latest.yml` болон багцууд татагдана.
 */
export const DEFAULT_UPDATE_FEED = 'https://public.template.gerege.mn/desktop/updates/';

/** Авто шалгалтын давтамж — 6 цаг (апп нээлттэй үед давтагдана). */
export const UPDATE_CHECK_INTERVAL_MS = 6 * 60 * 60 * 1000;

/**
 * Аппыг эхлүүлснээс хойш эхний шалгалт хүртэлх хугацаа. Нэвтрэлт, эхний
 * ачаалалттай зэрэг сүлжээ зурахгүйн тулд зориуд хойшлуулав.
 */
export const UPDATE_FIRST_CHECK_DELAY_MS = 30 * 1000;

/** Хадгалагдсан төлөвийн бүтэц (userData/state.json). */
export type DesktopState = {
  serverURL?: string;
  bounds?: { x?: number; y?: number; width: number; height: number };
  maximized?: boolean;
  /** Сүүлд шинэчлэлт шалгасан хугацаа (epoch ms) — дахин эхлэх бүрд давтахгүйн тулд. */
  lastUpdateCheck?: number;
};

/**
 * Ачаалах хаягийг тодорхойлно. Эрэмбэ: орчны хувьсагч → хадгалсан сонголт →
 * үндсэн утга. Буруу/аюултай хаягийг чимээгүй хаяж үндсэн утга руу буцна.
 */
export function resolveAppURL(env: string | undefined, stored: string | undefined): string {
  return normalizeAppURL(env) ?? normalizeAppURL(stored) ?? DEFAULT_APP_URL;
}

/**
 * Хэрэглэгчийн оруулсан хаягийг цэгцэлнэ: зөвхөн http/https, зөвхөн origin
 * (зам, query, fragment-ыг хасна). Тохирохгүй бол `null`.
 */
export function normalizeAppURL(raw: string | undefined | null): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;

  // Схемгүй бичсэн бол https гэж үзнэ ("template.gerege.mn" → https://…). Гэхдээ
  // зөвхөн хостын дүр төрхтэй байвал — эс тэгвэл ямар ч утга (жишээ нь санамсаргүй
  // үг) хүчинтэй IDN хост болж хувирч, ойлгомжгүй origin руу аваачна.
  const hasScheme = /^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(trimmed);
  if (!hasScheme) {
    const bareHost = (trimmed.split('/')[0] ?? '').split(':')[0] ?? '';
    if (bareHost !== 'localhost' && !bareHost.includes('.')) return null;
  }
  const candidate = hasScheme ? trimmed : `https://${trimmed}`;

  let url: URL;
  try {
    url = new URL(candidate);
  } catch {
    return null;
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return null;
  if (!url.hostname) return null;
  return url.origin;
}

/** Loopback хаяг уу — зөвхөн локал турших сувагт http зөвшөөрөхөд. */
function isLoopback(hostname: string): boolean {
  const h = hostname.toLowerCase();
  return h === 'localhost' || h === '127.0.0.1' || h === '::1' || h === '[::1]';
}

/**
 * Шинэчлэлтийн сувгийн хаягийг цэгцэлнэ.
 *
 * `normalizeAppURL`-ээс ялгаатай нь ЗАМЫГ хадгална (суваг нь `/desktop/updates/`
 * гэх мэт дэд зам байж болно) ба зөвхөн **https** зөвшөөрнө: сувгийн `latest*.yml`
 * нь багцын sha512-г тээдэг тул plaintext http дээр дайрагч yml ба багцыг хамт
 * сольж чадна. Локал турших зорилгоор loopback дээр http-г үлдээв.
 */
export function normalizeFeedURL(raw: string | undefined | null): string | null {
  if (!raw) return null;
  const trimmed = raw.trim();
  if (!trimmed) return null;

  let url: URL;
  try {
    url = new URL(trimmed);
  } catch {
    return null;
  }
  if (url.protocol === 'http:' ? !isLoopback(url.hostname) : url.protocol !== 'https:') return null;
  if (!url.hostname) return null;

  // Суваг нь лавлах — query/fragment утгагүй, төгсгөлийн ташуу зураас заавал.
  url.search = '';
  url.hash = '';
  if (!url.pathname.endsWith('/')) url.pathname = `${url.pathname}/`;
  return url.toString();
}

/**
 * Шинэчлэлтийн сувгийг тодорхойлно: орчны хувьсагч (staging турших) → үндсэн утга.
 * Хэрэглэгчийн сонгосон утгыг ЗОРИУД дэмжихгүй — суваг солих нь код солихтой
 * дүйцэх тул UI-аас нээх нь довтолгооны гадаргуу болно.
 */
export function resolveFeedURL(env: string | undefined): string {
  return normalizeFeedURL(env) ?? DEFAULT_UPDATE_FEED;
}
