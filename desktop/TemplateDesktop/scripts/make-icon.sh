#!/usr/bin/env bash
# Gerege Template Platform V3.0
# Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.
#
# Аппын дүрсийг web-ийн брэнд зурагнаас (frontend/public/brand.webp) үүсгэнэ.
#
# Гаралт:
#   resources/icon.png   — 1024×1024. Linux шууд хэрэглэнэ; Windows-ийн .ico-г
#                          electron-builder эндээс АВТОМАТААР хөрвүүлнэ
#                          (256px-ээс дээш png шаардлагатай).
#   resources/icon.icns  — macOS. Зөвхөн macOS дээр үүснэ (iconutil хэрэгтэй).
#
# Хэрэгслүүд: macOS дээр суурин sips + iconutil; бусад OS дээр ImageMagick
# (`magick` эсвэл `convert`). Аль нэг нь байхад л хангалттай.
#
# Хэрэглээ (desktop/TemplateDesktop дотроос):  npm run icon

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
source_image="$root/frontend/public/brand.webp"
resources="$here/../resources"

if [[ ! -f "$source_image" ]]; then
  echo "Эх зураг олдсонгүй: $source_image" >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$resources"

# Хөрвүүлэгчийг сонгоно: sips (macOS) → magick → convert.
if command -v sips >/dev/null 2>&1; then
  engine=sips
elif command -v magick >/dev/null 2>&1; then
  engine=magick
elif command -v convert >/dev/null 2>&1; then
  engine=convert
else
  echo "Зураг боловсруулах хэрэгсэл алга — sips (macOS) эсвэл ImageMagick суулгана уу." >&2
  exit 1
fi

# $1 = хэмжээ, $2 = гаралтын зам. Эх зургаас квадрат PNG гаргана.
resize() {
  local size="$1" out="$2"
  case "$engine" in
    sips)   sips -s format png -z "$size" "$size" "$work/base.png" --out "$out" >/dev/null ;;
    magick) magick "$work/base.png" -resize "${size}x${size}" "$out" ;;
    convert) convert "$work/base.png" -resize "${size}x${size}" "$out" ;;
  esac
}

# 1024px суурь PNG — бусад бүх хэмжээ эндээс жижигрэнэ.
case "$engine" in
  sips)   sips -s format png -z 1024 1024 "$source_image" --out "$work/base.png" >/dev/null ;;
  magick) magick "$source_image" -resize 1024x1024 "$work/base.png" ;;
  convert) convert "$source_image" -resize 1024x1024 "$work/base.png" ;;
esac

# --- Linux + Windows: нэг 1024px PNG ---
cp "$work/base.png" "$resources/icon.png"
echo "Үүслээ: $resources/icon.png (Linux; Windows .ico-г builder хөрвүүлнэ)"

# --- macOS: .icns ---
# iconutil нь зөвхөн macOS дээр байдаг. Бусад OS дээр байгаа icns хэвээр үлдэнэ —
# mac багцлалт ямар ч тохиолдолд macOS хостоос л хийгддэг.
if ! command -v iconutil >/dev/null 2>&1; then
  echo "iconutil алга (macOS бус хост) — icon.icns алгасав." >&2
  exit 0
fi

iconset="$work/icon.iconset"
mkdir -p "$iconset"

for size in 16 32 128 256 512; do
  resize "$size" "$iconset/icon_${size}x${size}.png"
  resize "$((size * 2))" "$iconset/icon_${size}x${size}@2x.png"
done

iconutil --convert icns "$iconset" --output "$resources/icon.icns"
echo "Үүслээ: $resources/icon.icns (macOS)"
