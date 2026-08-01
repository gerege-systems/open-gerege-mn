// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Тест ажиллуулагч: `dist/`-ээс `*.test.js`-ийг олж `node --test`-д ТОДОРХОЙ
// замаар дамжуулна.
//
// Яагаад скрипт вэ: `node --test`-д файлын жагсаалт өгөх нь Node-ийн хувилбар,
// бүрхүүл хоёроос ХАМААРАХГҮЙ цорын ганц хэлбэр юм.
//
//   node --test dist/*.test.js       — cmd.exe глоб задалдаггүй (Windows унана)
//   node --test "dist/**/*.test.js"  — глоб дэмжлэг зөвхөн Node 22+
//   node --test dist                 — лавлах хайлт Node 20 дээр ажиллана,
//                                      шинэ хувилбарууд үүнийг файл гэж үзнэ
//
// Иймд жагсаалтыг энд JS-ээр гаргаж, аль ч Node дээр ижил ажиллуулна.

import { spawn } from 'node:child_process';
import { readdirSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const distDir = path.join(appDir, 'dist');

/** `dist/` дотроос (дэд лавлах ороод) тестийн файлуудыг цуглуулна. */
function collect(dir) {
  const found = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) found.push(...collect(full));
    else if (entry.name.endsWith('.test.js')) found.push(full);
  }
  return found;
}

let files;
try {
  files = collect(distDir).sort();
} catch {
  console.error('dist/ олдсонгүй — эхлээд `npm run build` ажиллуулна уу.');
  process.exit(1);
}

if (files.length === 0) {
  // Чимээгүй "0 тест давлаа" гэж мэдээлэх нь хамгийн аюултай хуурмаг ногоон —
  // тестүүд build-д ороогүй бол алдаа болгоно.
  console.error(`Тестийн файл олдсонгүй: ${distDir}`);
  process.exit(1);
}

const child = spawn(process.execPath, ['--test', ...files], { stdio: 'inherit' });
child.on('close', (code) => process.exit(code ?? 0));
