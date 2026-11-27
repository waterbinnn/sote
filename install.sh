#!/bin/sh
# Sote 설치 스크립트 (Apple Silicon, macOS 14 이상)
#   curl -fsSL https://raw.githubusercontent.com/waterbinnn/sote/main/install.sh | sh
#
# curl 로 받은 파일에는 격리(quarantine) 표시가 붙지 않아서, 공증 전에도 경고 없이 열린다.
set -e

URL="https://github.com/waterbinnn/sote/releases/latest/download/Sote.zip"
DEST="${SOTE_DEST:-/Applications}"
[ -w "$DEST" ] || DEST="$HOME/Applications"
mkdir -p "$DEST"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Sote 내려받는 중..."
curl -fsSL "$URL" -o "$TMP/Sote.zip"
ditto -x -k "$TMP/Sote.zip" "$TMP"

# 실행 중이면 종료해야 덮어쓸 수 있다. 메모는 앱 설정에 저장돼 있어서 그대로 남는다.
[ -n "$SOTE_DEST" ] || osascript -e 'quit app "Sote"' >/dev/null 2>&1 || true
rm -rf "$DEST/Sote.app"
ditto "$TMP/Sote.app" "$DEST/Sote.app"

echo "설치 완료: $DEST/Sote.app"
[ -n "$SOTE_DEST" ] || open "$DEST/Sote.app"
