# keyd-macos-linux

Makes the physical **Alt** key (the one next to spacebar, where Cmd sits on
a real Mac keyboard) act like macOS's Command key on Linux/GNOME:

- **Alt+C / Alt+V / Alt+A / Alt+Z / Alt+T / Alt+W / ...** → Ctrl+C / Ctrl+V /
  Ctrl+A / Ctrl+Z / Ctrl+T / Ctrl+W / etc. in GTK apps, browsers, etc.
- The **real Ctrl key is untouched** — terminal use (Ctrl+C to interrupt,
  readline bindings) still works exactly like it always has.
- **Tap Alt alone** → opens GNOME Activities/search, same as a bare tap of
  the Super key used to.
- **Alt+Tab, Alt+F4, GTK mnemonics** keep working, now via the old Super/Win
  key (which is remapped to send plain Alt) or via the Cmd key itself
  (unmapped keys under it fall back to real Alt+key — see below).

Uses [`keyd`](https://github.com/rvaiya/keyd), which remaps at the
kernel/evdev level, so it works under Wayland and X11, regardless of
desktop environment (tested on Fedora 44 + GNOME/Wayland).

## Install

```
git clone https://github.com/MatRanc/keyd-macos-linux.git
cd keyd-macos-linux
./install.sh
```

`install.sh` installs `keyd` via the `alternateved/keyd` COPR repo on
Fedora; on other distros, install `keyd` yourself first (see its
[README](https://github.com/rvaiya/keyd#installation)), then run
`install.sh` again — it'll skip straight to copying the config.

No logout/reboot needed; it takes effect immediately.

## Why didn't keyd's own bundled `macos.conf` just work?

keyd ships an [example for this exact purpose](https://github.com/rvaiya/keyd/blob/master/examples/macos.conf).
We didn't know that when we started — it was found partway through, already
installed on disk at `/usr/share/doc/keyd/examples/macos.conf` by the keyd
package itself — and tried it as the starting point. **It didn't work
out of the box**, for three concrete reasons (on keyd v2.6.0, Fedora 44,
GNOME/Wayland, October 2026):

1. **`alt` is not a valid key name.** The upstream `macos.conf` example
   uses `leftmeta = alt`. On keyd v2.6.0 this is silently rejected
   (`keyd check` reports "invalid key or action") — the binding is just
   dropped, with no visible effect and no hard error at service start.
   The real name is `leftalt`: `leftmeta = leftalt`.

2. **Unqualified/wrong-modifier layers silently drop fallback behavior.**
   The upstream example uses `[meta_mac:C]` (inherit Ctrl) for its Cmd
   layer. If you instead write a plain `[cmd]` with no modifier suffix,
   any key you didn't explicitly remap (like Tab) comes out with **no**
   modifier at all once the layer is active — breaking Alt+Tab, Alt+F4,
   and GTK menu mnemonics the moment you hold the Cmd key. Use `[cmd:A]`
   (inherit Alt) so unmapped keys fall back to real Alt+key behavior.

3. **Disabling the overlay-key loses tap-to-search.** Upstream's example
   disables GNOME's "tap Super alone to open Activities" feature
   (`gsettings set org.gnome.mutter overlay-key ''`) because it no longer
   applies once Super stops being Super. Instead, just repoint it at the
   keysym your new Cmd key emits on a solo tap:
   `gsettings set org.gnome.mutter overlay-key 'Alt_L'`. Tap-to-search
   keeps working, just on the new key.

4. **Multi-OS keyboards can fight you before keyd even sees a keypress.**
   Keyboards like the Logitech Signature Slim K950/MK950 have a hardware
   OS-mode switch (`Fn+P` = Windows, `Fn+O` = macOS, `Fn+C` = ChromeOS)
   that changes which physical key sends which code *in firmware*. If
   it's set to macOS mode, the keyboard is already doing its own
   Alt/Cmd translation before keyd gets the event, which fights with
   whatever keyd config you write and makes remaps look like they're
   "not doing anything." Set it to **Windows mode** and let keyd do 100%
   of the remapping in software.

## Other existing solutions

We only found these while writing this README, after already building and
debugging the config above — we didn't evaluate or try them first, so this
isn't a claim that they have (or don't have) the same issues. If you're
choosing between options, they're worth a look too:

- [mac-keyboard-behavior-in-linux](https://github.com/stevenilsen123/mac-keyboard-behavior-in-linux) — a keyd script for this, tested on GNOME/PopOS.
- [Mac-Keyboard-Style-On-Linux](https://github.com/Anas-Alhariri/Mac-Keyboard-Style-On-Linux) — another keyd-based profile (2025).
- [mackeys](https://github.com/davidkellis/mackeys) — also keyd-based.

## Uninstall

```
sudo systemctl disable --now keyd
sudo rm /etc/keyd/default.conf
gsettings set org.gnome.mutter overlay-key 'Super'
```

## License

MIT
