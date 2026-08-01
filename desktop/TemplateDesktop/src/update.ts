// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Авто-шинэчлэлтийн ЦЭВЭР шийдвэрүүд. Electron болон electron-updater-ээс
// хамаарахгүй тул `node --test`-ээр шууд шалгагдана — сүлжээ, багц хэрэггүй.

/** Шинэчлэлтийн урсгалын үе шат. */
export type UpdatePhase =
  | 'idle' // юу ч болоогүй / сүүлд шалгахад шинэ хувилбар байгаагүй
  | 'checking' // суваг руу хандаж байна
  | 'downloading' // шинэ хувилбар олдож, татаж байна
  | 'ready' // татагдаж дуусаад дахин эхлэхийг хүлээж байна
  | 'error'; // сүүлийн оролдлого амжилтгүй

/** Шинэчлэлтийн одоогийн төлөв — цэсний шошго үүнээс гарна. */
export type UpdateStatus = {
  phase: UpdatePhase;
  /** Татаж буй хувилбарын дугаар (`downloading` / `ready` үед). */
  version?: string;
  /** Татсан хувь 0..100 (`downloading` үед). */
  percent?: number;
};

/**
 * Хувилбарын мөрийг тоон хэсгүүд + prerelease шошго болгон задална.
 * `1.2.3-beta.4` → { parts: [1,2,3], pre: ['beta', 4] }. Буруу бол `null`.
 */
function parseVersion(raw: string): { parts: number[]; pre: (string | number)[] } | null {
  const trimmed = raw.trim().replace(/^v/i, '');
  const match = /^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$/.exec(trimmed);
  if (!match) return null;

  const parts = [Number(match[1]), Number(match[2]), Number(match[3])];
  const pre = (match[4] ?? '')
    .split('.')
    .filter((s) => s.length > 0)
    .map((s) => (/^\d+$/.test(s) ? Number(s) : s));
  return { parts, pre };
}

/**
 * SemVer жишгээр харьцуулна: `a > b` бол 1, тэнцүү бол 0, бага бол -1.
 * Задлагдахгүй хувилбар бол `null` (шийдвэрийг дуудагч тал болгоомжтой авна).
 */
export function compareVersions(a: string, b: string): number | null {
  const va = parseVersion(a);
  const vb = parseVersion(b);
  if (!va || !vb) return null;

  for (let i = 0; i < 3; i += 1) {
    const x = va.parts[i] ?? 0;
    const y = vb.parts[i] ?? 0;
    if (x !== y) return x > y ? 1 : -1;
  }

  // Prerelease байхгүй нь ҮРГЭЛЖ илүү шинэ (1.0.0 > 1.0.0-beta.1).
  if (va.pre.length === 0 && vb.pre.length === 0) return 0;
  if (va.pre.length === 0) return 1;
  if (vb.pre.length === 0) return -1;

  const len = Math.max(va.pre.length, vb.pre.length);
  for (let i = 0; i < len; i += 1) {
    const x = va.pre[i];
    const y = vb.pre[i];
    if (x === undefined) return -1;
    if (y === undefined) return 1;
    if (x === y) continue;
    // Тоо нь тэмдэгт мөрөөс үргэлж бага эрэмбэтэй (SemVer 11.4.4).
    if (typeof x === 'number' && typeof y === 'number') return x > y ? 1 : -1;
    if (typeof x === 'number') return -1;
    if (typeof y === 'number') return 1;
    return x > y ? 1 : -1;
  }
  return 0;
}

/**
 * Санал болгож буй хувилбар нь суусан хувилбараас ШИНЭ үү.
 *
 * electron-updater өөрөө ч шалгадаг, гэхдээ буруу тохируулсан суваг (жишээ нь
 * staging руу заасан) хуучин багц санал болговол хэрэглэгчийг чимээгүй
 * "шинэчлэх" ёсгүй. Задлагдахгүй хувилбар бол `false` — татахгүй нь аюулгүй.
 */
export function isNewerVersion(candidate: string, current: string): boolean {
  return compareVersions(candidate, current) === 1;
}

/**
 * Авто шалгалт хийх цаг болсон уу. `lastCheck` байхгүй (анхны ажиллагаа) бол
 * тийм. Ирээдүйн цаг тэмдэглэгдсэн (систем цаг ухарсан) бол мөн тийм —
 * эс тэгвэл шалгалт мөнхөд гацна.
 */
export function shouldAutoCheck(now: number, lastCheck: number | undefined, intervalMs: number): boolean {
  if (lastCheck === undefined || !Number.isFinite(lastCheck)) return true;
  if (lastCheck > now) return true;
  return now - lastCheck >= intervalMs;
}

/** Цэсэнд харагдах шошго — төлөвөө хэрэглэгчид ил хэлнэ. */
export function updateMenuLabel(status: UpdateStatus): string {
  switch (status.phase) {
    case 'checking':
      return 'Шинэчлэлт шалгаж байна…';
    case 'downloading':
      return status.percent === undefined
        ? 'Шинэчлэлт татаж байна…'
        : `Шинэчлэлт татаж байна… ${Math.round(status.percent)}%`;
    case 'ready':
      return status.version
        ? `Шинэчлэлт бэлэн (${status.version}) — дахин эхлүүлэх`
        : 'Шинэчлэлт бэлэн — дахин эхлүүлэх';
    default:
      return 'Шинэчлэлт шалгах…';
  }
}

/** Цэсний зүйл дарагдах уу. Шалгаж/татаж байхад давхар эхлүүлэхээс сэргийлнэ. */
export function updateMenuEnabled(status: UpdateStatus): boolean {
  return status.phase !== 'checking' && status.phase !== 'downloading';
}

/**
 * electron-updater-ийн алдааг хүнд ойлгомжтой монгол тайлбар болгоно.
 * Техник мөрийг хаяхгүй — dialog-ийн `detail`-д хэвээр үзүүлнэ.
 */
export function describeUpdateError(message: string): string {
  const m = message.toLowerCase();
  if (m.includes('enotfound') || m.includes('econnrefused') || m.includes('enetunreach') || m.includes('getaddrinfo')) {
    return 'Шинэчлэлтийн сервертэй холбогдож чадсангүй. Интернэт холболтоо шалгана уу.';
  }
  if (m.includes('etimedout') || m.includes('timeout')) {
    return 'Шинэчлэлтийн сервер хариу өгсөнгүй. Дараа дахин оролдоно уу.';
  }
  if (m.includes('404') || m.includes('not found')) {
    return 'Шинэчлэлтийн суваг олдсонгүй. Апп буруу хаяг руу заасан байж болзошгүй.';
  }
  if (m.includes('sha512') || m.includes('checksum') || m.includes('integrity')) {
    return 'Татсан багцын бүрэн бүтэн байдал зөрлөө. Аюулгүйн үүднээс суулгасангүй.';
  }
  if (m.includes('code signature') || m.includes('not signed') || m.includes('codesign')) {
    return 'Багцын гарын үсэг тохирсонгүй. Гарын үсэггүй build дээр авто-шинэчлэлт ажиллахгүй.';
  }
  return 'Шинэчлэлт шалгах явцад алдаа гарлаа.';
}
