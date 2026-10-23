<p align="center"><img src="docs/icon.png" width="128" alt="Clippo icon"></p>

<h1 align="center">Clippo</h1>

<p align="center">A small, private clipboard manager for macOS — history, saved snippets and a paste queue.<br>
Free and open source. No account, no telemetry, works offline.</p>

<p align="center"><a href="#install">Install</a> · <a href="#features">Features</a> · <a href="#privacy">Privacy</a> · <a href="#по-русски">По-русски</a></p>

---

## Features

- **History** (`⌘;`) — everything you copy, text and images, searchable. `⌘1`–`⌘9` pastes an item instantly.
- **Snippet lists** (`⌘I`) — your own lists of phrases; digits `1`–`0` paste a line.
- **Paste Queue** (`⌘'`) — copy several things in a row, then press `⌘V` repeatedly to paste them in order.
  `⇧⌘C` copies a selection line by line into the queue (a column → N pastes), `⇧⌘X` clears it.
- **Images** — screenshots and copied pictures are kept with thumbnails and pasted back as images.
- **Your shortcuts** — every shortcut can be changed in Settings.
- **Floating panels** that don't steal focus: the app you're pasting into stays in front.
- Native Swift (AppKit + SwiftUI), no dependencies, ~2 MB.

## Privacy

Clippo is built for people who copy passwords, keys and client data all day.

- **Passwords are never saved.** Copies marked as secret by password managers (1Password, Bitwarden, Apple Passwords
  and anything following the [nspasteboard.org](http://nspasteboard.org) convention) are skipped.
- **Exclude apps.** Nothing copied in Keychain Access or Passwords is recorded by default; add banks, browsers or work
  tools in Settings.
- **Encrypted on disk.** History, queue and images are stored with AES-GCM, not as plain text.
- **Clear on quit**, or clear history with one click.
- **Offline.** Your history never leaves your Mac. The only network request is an optional daily update check (off by default).

Clippo needs **Accessibility** permission only to press `⌘V` for you. It does not record keystrokes.

## Install

Requires macOS 14 or later.

1. Download `Clippo.zip` from [Releases](../../releases) and unzip it.
2. Move `Clippo.app` to **Applications** and open it.
3. macOS will say it can't verify the developer — Clippo isn't signed with a paid Apple certificate yet.
   Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway**.
4. Clippo shows a short welcome window. Turn on Clippo in **Accessibility** when asked.

The icon lives in the menu bar. Launch Clippo again from Spotlight to open Settings.

### Build from source

```bash
git clone https://github.com/Lorder19/clippo.git
cd clippo
./build.sh install
```

Needs Xcode command line tools. Without a stable signing identity the build is signed ad-hoc, so macOS asks for
Accessibility again after each rebuild. To avoid that, create a self-signed code-signing certificate named
`Clippo Local Signing` in Keychain Access.

## Support

Clippo is free. If it saves you time, a donation keeps it going — see the Sponsor button on this page.

## License

MIT

---

## По-русски

**Clippo** — лёгкий приватный менеджер буфера обмена для macOS. Бесплатный, с открытым кодом, без аккаунтов и интернета.

- `⌘;` — история скопированного (текст и картинки) с поиском, `⌘1`–`⌘9` — вставить сразу.
- `⌘I` — свои списки фраз, цифры вставляют строку.
- `⌘'` — Paste Queue: копируете подряд, `⌘V` вставляет по очереди. `⇧⌘C` — построчно в очередь, `⇧⌘X` — очистить.
- Пароли из менеджеров паролей не записываются, есть исключения по программам, история зашифрована на диске.
- Все сочетания меняются в настройках.

**Установка:** скачайте `Clippo.zip` в [Releases](../../releases), перенесите Clippo в «Программы» и откройте.
macOS предупредит о неизвестном разработчике — зайдите в **Системные настройки → Конфиденциальность и безопасность**
и нажмите **«Всё равно открыть»**. Затем включите Clippo в **Универсальном доступе** — он нужен только чтобы нажимать `⌘V` за вас.
