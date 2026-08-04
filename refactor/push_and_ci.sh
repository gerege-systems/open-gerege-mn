#!/usr/bin/env bash
# Gerege Modular Refactor — patch-уудыг core репод оруулж CI-д push хийх скрипт.
# Хэрэглээ:
#   ./push_and_ci.sh /path/to/open-gerege-core
# Юу хийдэг:
#   1) refactor/modular-framework branch үүсгэнэ (main-ээс)
#   2) refactor/patches/00*.patch-уудыг git am --3way-ээр оруулна
#   3) origin руу push хийнэ
#   4) gh CLI байвал PR нээнэ (CI нь pull_request дээр бүрэн ажиллана —
#      main руу шууд push хийхгүй тул deploy trigger болохгүй)
set -euo pipefail

CORE="${1:?хэрэглээ: ./push_and_ci.sh /path/to/open-gerege-core}"
PATCHES="$(cd "$(dirname "$0")/patches" && pwd)"
BRANCH="refactor/modular-framework"

cd "$CORE"
git diff --quiet || { echo "!! Ажлын сан цэвэр биш — эхлээд commit/stash хийнэ үү"; exit 1; }
git fetch origin
git checkout -B "$BRANCH" origin/main

echo "==> Applying $(ls "$PATCHES"/00*.patch | wc -l | tr -d ' ') patches"
git am --3way "$PATCHES"/00*.patch

echo "==> Local CI mirror (түргэн шалгалт)"
gofmt -l . | grep -v '^docs/' && { echo "!! gofmt"; exit 1; } || true
go build ./...

git push -u origin "$BRANCH"

if command -v gh >/dev/null 2>&1; then
  gh pr create --base main --head "$BRANCH" \
    --title "feat: V4.0 modular framework (kernel/module, lifecycle, platformd, gerege CLI)" \
    --body "Modular Platform refactor Phase 0–1 + lifecycle + platformd + CLI. 10 commits, details in each message. Golden route inventory unchanged; 55 pkg -race green locally. See open-gerege-mn/refactor/REFACTOR_PROGRESS_REPORT*.md" \
    || echo "(PR аль хэдийн байгаа бол OK)"
else
  echo "gh CLI алга — PR-ээ вэбээс нээнэ үү: https://github.com/gerege-systems/open-gerege-core/compare/$BRANCH"
fi

echo "==> Done. CI: https://github.com/gerege-systems/open-gerege-core/actions"
