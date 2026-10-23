<p align="center"><img src="docs/icon.png" width="112" alt=""></p>

<h1 align="center">Clippo</h1>

<p align="center">Clipboard history for the Mac. Small, free, open source.<br>
<a href="https://lorder19.github.io/clippo/">Website</a> · <a href="https://github.com/Lorder19/clippo/releases/latest">Download</a></p>

<p align="center">
<a href="https://github.com/Lorder19/clippo/releases/latest"><img src="https://img.shields.io/github/v/release/Lorder19/clippo?label=version&color=c8232f" alt="Latest version"></a>
<a href="https://github.com/Lorder19/clippo/releases"><img src="https://img.shields.io/github/downloads/Lorder19/clippo/total?color=555" alt="Downloads"></a>
<a href="https://github.com/Lorder19/clippo/actions/workflows/build.yml"><img src="https://github.com/Lorder19/clippo/actions/workflows/build.yml/badge.svg" alt="Build"></a>
<img src="https://img.shields.io/badge/macOS-14%2B-555" alt="macOS 14+">
</p>

<p align="center"><img src="docs/screenshots/history.png" width="560" alt="History window"></p>

I used CleanClip for years. After a macOS update it started crashing, and the alternatives I tried either wanted a subscription or did too much. So I wrote my own. Clippo does three things and tries to stay out of the way.

## What it does

Press ⌘; to see what you copied recently, text and images. Type to search, hit ⌘1 to ⌘9 to paste one of the first nine.

Press ⌘I for your saved lists: canned replies, addresses, whatever you paste often. A digit pastes a line.

Press ⌘' for the paste queue. Copy a few things in a row, then every ⌘V pastes the next one. ⇧⌘C takes a selected column (from a spreadsheet, a log, anything) and queues it line by line. ⇧⌘X empties the queue.

<p align="center">
  <img src="docs/screenshots/queue.png" width="260" alt="Paste queue">
  <img src="docs/screenshots/list.png" width="260" alt="Saved lists">
</p>

All shortcuts can be changed in Settings. The panels float over whatever you're working in and don't take focus away from it, so the paste lands where you expect.

## About your data

A clipboard manager sees everything you copy, so I tried to be careful:

* Passwords copied from 1Password, Bitwarden, Apple Passwords and other managers that mark them as concealed are never saved.
* You can list apps whose copies should be ignored (Keychain Access and Passwords are there by default).
* History and images are encrypted on disk (AES-GCM). The key sits next to the data, readable only by your user account, so this protects against the file leaking, not against someone who has your login.
* Clippo windows are marked private: macOS screenshots skip them and they don't show up when you share your screen in Telegram. A few recording apps ignore that flag, so check yours if it matters.
* Nothing is sent anywhere. The one exception is a daily update check against GitHub, and it's off unless you turn it on.

Clippo needs Accessibility permission for one thing: pressing ⌘V for you after you pick an item. It doesn't log keystrokes.

## Install

macOS 14 or newer, Apple Silicon or Intel.

With Homebrew:

```bash
brew install --cask lorder19/tap/clippo
```

Or by hand:

1. Download `Clippo.zip` from [Releases](https://github.com/Lorder19/clippo/releases/latest), unzip, drag Clippo into Applications.
2. Open it. macOS will say it can't check the developer, because I don't have a paid Apple developer account yet. Go to System Settings → Privacy & Security, scroll down, click "Open Anyway".
3. Turn Clippo on in Accessibility when it asks.

The icon lives in the menu bar. If it's hidden behind the notch, open Clippo again from Spotlight and you'll get the settings window.

To uninstall, quit Clippo and delete the app and `~/Library/Application Support/Clippo`.

## Building it yourself

```bash
git clone https://github.com/Lorder19/clippo.git
cd clippo
./build.sh install
```

You need the Xcode command line tools. Without a fixed signing certificate the build is signed ad hoc, which means macOS asks for Accessibility again after every rebuild. Create a self-signed code signing certificate called `Clipo Local Signing` in Keychain Access to avoid that.

`Clippo -ClippoDemo history` (or `list`, `queue`, `settings`) opens a window filled with sample data. That's how the screenshots are made; your real history isn't touched.

## Languages

English, Russian, Simplified Chinese. If you'd like to add yours, the strings are in `Resources/`.

## Feedback

Bugs go to [Issues](https://github.com/Lorder19/clippo/issues), questions and ideas to [Discussions](https://github.com/Lorder19/clippo/discussions). Want to help? See [CONTRIBUTING](CONTRIBUTING.md). What changed in each version is in the [changelog](CHANGELOG.md). If Clippo saves you time, a star helps other people find it.

MIT license.

---

### По-русски

Clippo это менеджер буфера обмена для Mac. Бесплатный, с открытым кодом, без аккаунтов. ⌘; открывает историю (текст и картинки), ⌘I ваши списки фраз, ⌘' очередь вставки: копируете несколько вещей подряд, а ⌘V вставляет их по одной. Пароли из менеджеров паролей не сохраняются, история на диске зашифрована.

Скачать можно в [Releases](https://github.com/Lorder19/clippo/releases/latest). При первом запуске macOS предупредит о неизвестном разработчике: Системные настройки → Конфиденциальность и безопасность → «Всё равно открыть». Потом включите Clippo в Универсальном доступе.
