# Sote

항상 화면 위에 띄워 두는 스티커 메모 앱 (macOS).

- 구름, 말풍선, 하트, 반짝 등 11가지 스티커 모양
- 메모마다 **항상 위에 고정** 켜기/끄기 — 끄면 평소엔 다른 창 아래에 있다가, 앱을 누르면 맨 앞으로
- 메모마다 색상(파스텔 14색 + 블랙), 글자 크기, 글자 굵기, 글자 정렬 선택
- 메뉴바 아이콘에서 모양 미리보기를 보고 바로 새 메모 추가
- 드래그로 이동, 더블클릭으로 입력, 핀치 또는 오른쪽 아래 손잡이로 크기 조절

## 설치

Apple Silicon Mac, macOS 14 이상. 터미널에 아래 한 줄을 붙여 넣으면 응용 프로그램 폴더에 설치되고 바로 실행됩니다.

```sh
curl -fsSL https://raw.githubusercontent.com/waterbinnn/sote/main/install.sh | sh
```

1.2.0부터는 메뉴바 아이콘이나 Sote 메뉴의 **업데이트 확인…** 을 누르면 새 버전으로 업데이트됩니다. 그 전 버전은 같은 명령을 한 번 더 실행해 주세요. 메모는 그대로 남습니다.

<details>
<summary>zip 파일로 직접 설치하기</summary>

[Releases](https://github.com/waterbinnn/sote/releases)에서 `Sote.zip`을 받아 `Sote.app`을 응용 프로그램 폴더로 옮깁니다.
Developer ID로 서명하고 Apple 공증(notarize)을 받은 앱이라 경고 없이 바로 열립니다.

</details>

## 직접 빌드

macOS 14 이상, Xcode(또는 Swift 툴체인)가 필요합니다.

```sh
./build.sh && open Sote.app
```

키체인에 Developer ID 인증서가 있으면 그것으로 서명하고, 없으면 임시(ad-hoc) 서명합니다.
배포용으로 공증받은 `Sote.zip`을 만들려면 `./release.sh`를 실행합니다(사용법은 파일 맨 위 주석 참고).
