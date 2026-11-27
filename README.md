# Sote

**English** | [한국어](README.ko.md)

Sticker notes that float on your screen (macOS).

- 11 sticker shapes, including Cloud, Speech Bubble, Heart and Sparkle
- Turn **Always on Top** on or off per note. When it's off, the note stays behind other windows until you click the app
- Pick a color (14 pastels + black), font size, font weight and alignment for each note
- Add a new note straight from the menu bar icon, with a preview of every shape
- Drag to move, double-click to type, and pinch or drag the bottom-right handle to resize

## Install

Runs on Apple Silicon Macs with macOS 14 or later. Sote is notarized by Apple, so it opens without security warnings.

### Download

1. [**Download Sote.zip**](https://github.com/waterbinnn/sote/releases/latest/download/Sote.zip)
2. Unzip it and move `Sote.app` to your **Applications** folder.
3. Open Sote from the Applications folder. Its icon appears in the menu bar.

Make sure to move Sote to the Applications folder before opening it. If you open it straight from Downloads, it can't update itself later.

### Install from Terminal

Paste this line into Terminal to install Sote into your Applications folder and open it.

```sh
curl -fsSL https://raw.githubusercontent.com/waterbinnn/sote/main/install.sh | sh
```

### Update

Click **Check for Updates…** in the menu bar icon or the Sote menu. Versions before 1.2.0 don't have this menu, so reinstall with either method above. Your notes are kept either way.

### Uninstall

Move `Sote.app` from the Applications folder to the Trash. To delete your notes too, also delete `~/Library/Preferences/app.sote.note.plist`.

## Build from source

Requires macOS 14 or later and Xcode (or a Swift toolchain).

```sh
./build.sh && open Sote.app
```

If the keychain has a Developer ID certificate, the build is signed with it. Otherwise it's ad-hoc signed.
To make a notarized `Sote.zip` for release, run `./release.sh` (see the comments at the top of the file).
