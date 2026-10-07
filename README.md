# lidgo

[![CI](https://github.com/babAdamino/lidgo/actions/workflows/ci.yml/badge.svg)](https://github.com/babAdamino/lidgo/actions/workflows/ci.yml)
[![latest release](https://img.shields.io/github/v/release/babAdamino/lidgo)](https://github.com/babAdamino/lidgo/releases/latest)

Keep your MacBook awake with the lid closed, on battery, with no external display.
One menu-bar switch, with an auto-off timer and a battery-floor cutoff so you never
drain it flat.

## Install

### From the dmg (easiest)

Download the latest `lidgo-<version>.dmg` from
[Releases](https://github.com/babAdamino/lidgo/releases/latest), open it, and drag
lidgo into Applications. Then run the one-time grant so the app can toggle sleep
without a password prompt:

```sh
/Applications/lidgo.app/Contents/Resources/grant.sh
```

Launch lidgo, click the menu-bar icon, flip Enable on, and close the lid.

> lidgo is ad-hoc signed, not notarized (no paid Apple Developer account). On first
> launch macOS will refuse to open it. Right-click (or Control-click) the app,
> choose **Open**, then **Open** again to allow it. To verify the download first:
> `shasum -a 256 -c SHA256SUMS` (see [docs/AUDIT.md](docs/AUDIT.md)).

### From source

```sh
git clone https://github.com/babadamino/lidgo.git
cd lidgo
./install.sh
```

Then click the lidgo icon in the menu bar, flip Enable on, and close the lid.

## Features

- **One switch**: flip Enable and the Mac stays awake with the lid closed.
- **Auto-off timer**: 1h or 2h with a live countdown, then off.
- **Battery floor**: auto-off at 5–50% on battery (default 15%).
- **Low Power Mode**: steps aside when LPM is on, on battery.
- **Launch at login**: optional, off by default, always starts idle.
- **Tiny + native**: one AppKit file. No Dock icon, daemon, or kext.

Menu-bar glyph: dimmed = off · full = awake · full + dot = awake on battery
(auto-off live).

## How it works

lidgo toggles `pmset disablesleep` (the kernel's `SleepDisabled` flag), reads it
back so the menu bar never lies, and reverts it at your battery floor, in Low
Power Mode, when the timer ends, or on reboot. A GUI app can't type a password,
so the installer adds a scoped sudoers rule for **exactly two commands**:

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

See [docs/AUDIT.md](docs/AUDIT.md).

## Uninstall

```sh
./uninstall.sh
```

Restores normal sleep, removes the app, login item, and sudoers grant, then
proves the grant is gone.

## License

[MIT](LICENSE) © 2026 babAdamino.
