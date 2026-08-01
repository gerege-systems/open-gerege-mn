// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

// Авто-шинэчлэлтийн шийдвэрүүдийн тест. Энэ давхарга буруу ажиллавал апп
// ХУУЧИН багц татаж, эсвэл шалгалт мөнхөд гацна — тиймээс хилүүдийг барина.
// Ажиллуулах: `npm test` (tsc → `node --test dist/*.test.js`).

import assert from 'node:assert/strict';
import { test } from 'node:test';
import { DEFAULT_UPDATE_FEED, normalizeFeedURL, resolveFeedURL } from './config';
import {
  compareVersions,
  describeUpdateError,
  isNewerVersion,
  shouldAutoCheck,
  updateMenuEnabled,
  updateMenuLabel,
} from './update';

// ---------------------------------------------------------------- суваг

test('сувгийн хаяг зөвхөн https (loopback дээр http зөвшөөрнө)', () => {
  assert.equal(normalizeFeedURL('https://template.gerege.mn/desktop/updates/'), 'https://template.gerege.mn/desktop/updates/');
  assert.equal(normalizeFeedURL('http://localhost:8080/updates/'), 'http://localhost:8080/updates/');
  assert.equal(normalizeFeedURL('http://127.0.0.1:8080/updates/'), 'http://127.0.0.1:8080/updates/');
  // Гуравдагч этгээд yml + багцыг хамт солих боломжтой тул plaintext хаана.
  assert.equal(normalizeFeedURL('http://updates.gerege.mn/'), null);
  assert.equal(normalizeFeedURL('ftp://updates.gerege.mn/'), null);
  assert.equal(normalizeFeedURL('file:///tmp/updates/'), null);
  assert.equal(normalizeFeedURL('updates.gerege.mn'), null);
  assert.equal(normalizeFeedURL(''), null);
  assert.equal(normalizeFeedURL(undefined), null);
});

test('сувгийн хаягийн зам хадгалагдаж, төгсгөлийн ташуу зураас нэмэгдэнэ', () => {
  assert.equal(normalizeFeedURL('https://cdn.gerege.mn/desktop'), 'https://cdn.gerege.mn/desktop/');
  assert.equal(normalizeFeedURL('https://cdn.gerege.mn'), 'https://cdn.gerege.mn/');
  // query/fragment утгагүй — latest*.yml нь тогтмол нэртэй файл.
  assert.equal(normalizeFeedURL('https://cdn.gerege.mn/d/?t=1#x'), 'https://cdn.gerege.mn/d/');
});

test('суваг: орчны хувьсагч → үндсэн утга', () => {
  assert.equal(resolveFeedURL('https://staging.gerege.mn/updates/'), 'https://staging.gerege.mn/updates/');
  assert.equal(resolveFeedURL(undefined), DEFAULT_UPDATE_FEED);
  // Хүчингүй утга чимээгүй хаягдаж үндсэн суваг руу буцна.
  assert.equal(resolveFeedURL('http://evil.example/updates/'), DEFAULT_UPDATE_FEED);
});

// ------------------------------------------------------------ хувилбар

test('хувилбарыг semver жишгээр харьцуулна', () => {
  assert.equal(compareVersions('1.2.3', '1.2.3'), 0);
  assert.equal(compareVersions('1.2.4', '1.2.3'), 1);
  assert.equal(compareVersions('1.3.0', '1.2.9'), 1);
  assert.equal(compareVersions('2.0.0', '10.0.0'), -1); // мөрөөр биш тоогоор
  assert.equal(compareVersions('v1.2.3', '1.2.3'), 0);
  assert.equal(compareVersions('1.2.3+build.5', '1.2.3'), 0);
});

test('prerelease нь тогтвортой хувилбараас бага эрэмбэтэй', () => {
  assert.equal(compareVersions('1.0.0', '1.0.0-beta.1'), 1);
  assert.equal(compareVersions('1.0.0-beta.1', '1.0.0-beta.2'), -1);
  assert.equal(compareVersions('1.0.0-beta.2', '1.0.0-beta.10'), -1);
  assert.equal(compareVersions('1.0.0-alpha', '1.0.0-beta'), -1);
  assert.equal(compareVersions('1.0.0-beta', '1.0.0-beta.1'), -1);
});

test('задлагдахгүй хувилбар бол шийдвэр гаргахгүй', () => {
  assert.equal(compareVersions('1.2', '1.2.0'), null);
  assert.equal(compareVersions('хувилбар', '1.0.0'), null);
});

test('зөвхөн ШИНЭ хувилбарыг татна (буруу тохируулсан суваг ухраахгүй)', () => {
  assert.equal(isNewerVersion('1.0.1', '1.0.0'), true);
  assert.equal(isNewerVersion('1.0.0', '1.0.0'), false);
  assert.equal(isNewerVersion('0.9.9', '1.0.0'), false);
  assert.equal(isNewerVersion('1.0.0-beta.1', '1.0.0'), false);
  // Танихгүй мөр ирвэл татахгүй нь аюулгүй.
  assert.equal(isNewerVersion('латест', '1.0.0'), false);
});

// -------------------------------------------------------------- давтамж

test('авто шалгалтын давтамж', () => {
  const HOUR = 60 * 60 * 1000;
  const now = 1_000 * HOUR;
  // Анхны ажиллагаа — тэмдэглэл байхгүй.
  assert.equal(shouldAutoCheck(now, undefined, 6 * HOUR), true);
  assert.equal(shouldAutoCheck(now, now - 5 * HOUR, 6 * HOUR), false);
  assert.equal(shouldAutoCheck(now, now - 6 * HOUR, 6 * HOUR), true);
  // Системийн цаг ухарсан — шалгалт мөнхөд гацахаас сэргийлнэ.
  assert.equal(shouldAutoCheck(now, now + 100 * HOUR, 6 * HOUR), true);
  assert.equal(shouldAutoCheck(now, Number.NaN, 6 * HOUR), true);
});

// ----------------------------------------------------------------- цэс

test('цэсний шошго төлөвөө хэлнэ', () => {
  assert.equal(updateMenuLabel({ phase: 'idle' }), 'Шинэчлэлт шалгах…');
  assert.equal(updateMenuLabel({ phase: 'checking' }), 'Шинэчлэлт шалгаж байна…');
  assert.equal(updateMenuLabel({ phase: 'downloading', percent: 41.6 }), 'Шинэчлэлт татаж байна… 42%');
  assert.equal(updateMenuLabel({ phase: 'downloading' }), 'Шинэчлэлт татаж байна…');
  assert.equal(updateMenuLabel({ phase: 'ready', version: '1.1.0' }), 'Шинэчлэлт бэлэн (1.1.0) — дахин эхлүүлэх');
  assert.equal(updateMenuLabel({ phase: 'error' }), 'Шинэчлэлт шалгах…');
});

test('шалгаж / татаж байхад цэсээр давхар эхлүүлэхгүй', () => {
  assert.equal(updateMenuEnabled({ phase: 'idle' }), true);
  assert.equal(updateMenuEnabled({ phase: 'error' }), true);
  assert.equal(updateMenuEnabled({ phase: 'ready' }), true);
  assert.equal(updateMenuEnabled({ phase: 'checking' }), false);
  assert.equal(updateMenuEnabled({ phase: 'downloading', percent: 10 }), false);
});

// -------------------------------------------------------------- алдаа

test('алдааг хүнд ойлгомжтой болгоно', () => {
  assert.match(describeUpdateError('getaddrinfo ENOTFOUND template.gerege.mn'), /холбогдож чадсангүй/);
  assert.match(describeUpdateError('connect ETIMEDOUT 10.0.0.1:443'), /хариу өгсөнгүй/);
  assert.match(describeUpdateError('HttpError: 404 Not Found'), /суваг олдсонгүй/);
  assert.match(describeUpdateError('sha512 checksum mismatch'), /бүрэн бүтэн байдал/);
  assert.match(describeUpdateError('Could not get code signature for running application'), /гарын үсэг/);
  assert.match(describeUpdateError('ямар нэг тодорхойгүй асуудал'), /алдаа гарлаа/);
});
