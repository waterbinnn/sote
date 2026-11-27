# Sote

[English](README.md) | **한국어**

항상 화면 위에 띄워 두는 스티커 메모 앱 (macOS).

- 구름(Cloud), 말풍선(Speech Bubble), 하트(Heart), 반짝(Sparkle) 등 11가지 스티커 모양
- 메모마다 **Always on Top**(항상 위에 고정)을 켜고 끌 수 있습니다. 끄면 평소에는 다른 창 아래에 있다가, 앱을 누르면 맨 앞으로 나옵니다
- 메모마다 색상(파스텔 14색 + 블랙), 글자 크기, 글자 굵기, 글자 정렬 선택
- 메뉴바 아이콘에서 모양 미리보기를 보고 바로 새 메모 추가
- 드래그로 이동, 더블클릭으로 입력, 핀치 또는 오른쪽 아래 손잡이로 크기 조절

## 설치

Apple Silicon Mac, macOS 14 이상에서 실행됩니다. Apple 공증(notarize)을 받은 앱이라 보안 경고 없이 열립니다.

### 내려받아 설치

1. [**Sote.zip 내려받기**](https://github.com/waterbinnn/sote/releases/latest/download/Sote.zip)
2. 압축을 풀고 `Sote.app`을 **응용 프로그램** 폴더로 옮깁니다.
3. 응용 프로그램 폴더에서 Sote를 엽니다. 메뉴바에 아이콘이 생깁니다.

다운로드 폴더에서 바로 열면 나중에 앱 안에서 업데이트할 수 없으니, 꼭 응용 프로그램 폴더로 옮긴 뒤 여세요.

### 터미널로 설치

아래 한 줄을 붙여 넣으면 응용 프로그램 폴더에 설치하고 바로 실행합니다.

```sh
curl -fsSL https://raw.githubusercontent.com/waterbinnn/sote/main/install.sh | sh
```

### 업데이트

메뉴바 아이콘이나 Sote 메뉴의 **Check for Updates…**(업데이트 확인)를 누르세요. 1.2.0보다 오래된 버전은 이 메뉴가 없으니 위 설치 방법 중 하나로 다시 설치하면 됩니다. 어느 경우든 메모는 그대로 남습니다.

### 삭제

응용 프로그램 폴더의 `Sote.app`을 휴지통으로 옮깁니다. 메모까지 지우려면 `~/Library/Preferences/app.sote.note.plist`도 지우세요.

## 직접 빌드

macOS 14 이상, Xcode(또는 Swift 툴체인)가 필요합니다.

```sh
./build.sh && open Sote.app
```

키체인에 Developer ID 인증서가 있으면 그것으로 서명하고, 없으면 임시(ad-hoc) 서명합니다.
배포용으로 공증받은 `Sote.zip`을 만들려면 `./release.sh`를 실행합니다(사용법은 파일 맨 위 주석 참고).
