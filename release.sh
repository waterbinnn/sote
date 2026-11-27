#!/bin/sh
# 공증(notarize)된 배포용 Sote.zip 을 만든다. 사용법: ./release.sh
#
# 처음 한 번, 공증용 자격 증명을 키체인에 저장해 둔다(앱 암호는 appleid.apple.com 에서 발급):
#   xcrun notarytool store-credentials sote --apple-id <Apple ID> --team-id PX5UDD7799
# 다른 이름으로 저장했다면 NOTARY_PROFILE=<이름> ./release.sh
set -e
cd "$(dirname "$0")"
PROFILE="${NOTARY_PROFILE:-sote}"

./build.sh
codesign -dvv Sote.app 2>&1 | grep -q "Authority=Developer ID Application" \
  || { echo "Developer ID 로 서명되지 않아 공증할 수 없습니다." >&2; exit 1; }

rm -f Sote.zip
ditto -c -k --keepParent Sote.app Sote.zip
echo "공증 요청 중... (보통 1~5분)"
xcrun notarytool submit Sote.zip --keychain-profile "$PROFILE" --wait

# 공증 티켓을 앱에 붙여(staple) 오프라인에서도 바로 열리게 하고, 티켓이 붙은 앱으로 다시 묶는다.
xcrun stapler staple Sote.app
rm -f Sote.zip
ditto -c -k --keepParent Sote.app Sote.zip
spctl -a -vv -t exec Sote.app

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Sote.app/Contents/Info.plist)
echo
echo "완료: Sote.zip ($VERSION)"
echo "GitHub 릴리스로 올리기:  gh release create v$VERSION Sote.zip --title v$VERSION"
