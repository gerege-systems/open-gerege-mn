// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Хөгжүүлэлтийн эхлүүлэгч: локал frontend рүү заасан Electron-ыг асаана.
//
// Яагаад скрипт вэ: `GEREGE_APP_URL=… electron .` гэсэн бичлэг нь POSIX бүрхүүл
// дээр л ажилладаг — Windows-ийн cmd/PowerShell дээр орчны хувьсагч тогтоохгүй,
// «GEREGE_APP_URL=… гэсэн команд олдсонгүй» гэж унана. Гуравдагч сан (cross-env)
// нэмэхийн оронд орчноо энд тогтоов.
//
// Хэрэглээ:  npm run dev  [-- <өөр хаяг>]

import { spawn } from 'node:child_process';
import { createRequire } from 'node:module';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
// `electron` пакет нь өөрийн хоёртын файлын замыг экспортолдог — платформ бүрд
// (.exe / .app / ELF) зөв зам буцаана.
const electron = require('electron');
const appDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const child = spawn(electron, [appDir], {
  stdio: 'inherit',
  env: {
    ...process.env,
    GEREGE_APP_URL: process.argv[2] ?? process.env.GEREGE_APP_URL ?? 'http://localhost:3000',
    GEREGE_DEVTOOLS: process.env.GEREGE_DEVTOOLS ?? '1',
  },
});

child.on('close', (code) => process.exit(code ?? 0));
