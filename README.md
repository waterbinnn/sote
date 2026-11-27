# Sote

항상 화면 위에 띄워 두는 스티커 메모 앱 (macOS).

- 구름, 말풍선, 하트, 반짝 등 11가지 스티커 모양
- 메모마다 **항상 위에 고정** 켜기/끄기 — 끄면 평소엔 다른 창 아래에 있다가, 앱을 누르면 맨 앞으로
- 메모마다 색상(파스텔 14색), 글자 크기, 글자 굵기, 글자 정렬 선택
- 메뉴바 아이콘에서 모양 미리보기를 보고 바로 새 메모 추가
- 드래그로 이동, 더블클릭으로 입력, 핀치·⌘=/⌘- 또는 오른쪽 아래 손잡이로 크기 조절

## 설치

Apple Silicon Mac, macOS 14 이상. 터미널에 아래 한 줄을 붙여 넣으면 응용 프로그램 폴더에 설치되고 바로 실행됩니다.

```sh
curl -fsSL https://raw.githubusercontent.com/waterbinnn/sote/main/install.sh | sh
```

업데이트할 때도 같은 명령을 다시 실행하면 됩니다. 메모는 그대로 남습니다.

<details>
<summary>zip 파일로 직접 설치하기</summary>

[Releases](https://github.com/waterbinnn/sote/releases)에서 `Sote.zip`을 받아 `Sote.app`을 응용 프로그램 폴더로 옮깁니다.
아직 공증(notarize)되지 않은 앱이라, 브라우저로 받으면 처음 열 때 macOS가 막습니다.
**시스템 설정 → 개인정보 보호 및 보안**에서 "그래도 열기"를 한 번 눌러 주세요.

</details>

## 직접 빌드

macOS 14 이상, Xcode(또는 Swift 툴체인)가 필요합니다.

```sh
./build.sh && open Sote.app
```
