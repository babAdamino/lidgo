# contributing to lidgo

lidgo is a lightweight, single-purpose menu-bar app. Any proposed changes should focus on keeping it small, NOT bloated, and macOS native.

## Ways to help

- **Report a bug**: use the bug-report issue form. Include your exact macOS version
  (`sw_vers`), your Mac model (`sysctl -n hw.model`), and what `pmset -g | grep SleepDisabled`
  reports before/after the problem.
- **Code**: bug fixes and small, focused improvements.

## Building locally

No Xcode project, just the Command Line Tools:

```sh
git clone https://github.com/babadamino/lidgo.git
cd lidgo
./build.sh            # builds ./build/lidgo.app, ad-hoc signed
open build/lidgo.app
```

`./install.sh` additionally installs the passwordless grant (it prints exactly
what it writes). Launch at login stays off; it is opt-in from the app's popover.
`./uninstall.sh` backs it all out and proves the grant is revoked.

## Coding guidelines

- **Keep it native.** lidgo uses AppKit and a bundled PNG glyph. No third-party
  dependencies, no bundled frameworks.
- **Zero warnings.** The build must compile clean:
  ```sh
  swiftc -O -parse-as-library -framework AppKit App.swift -o /tmp/lidgo
  ```
  CI runs the equivalent compile on every push/PR.
- **Match the surrounding style.** Read `App.swift` first and keep comment density, naming, and
  the "read back the real system state, never assume" discipline.
- **No personal paths or usernames** in scripts, the sudoers template, or install commands.
  The grant is generated from `$(id -un)` at install time.
- **Verify on a real machine.** lidgo is verified on macOS 26 (Tahoe) / Apple Silicon.
  If you test on other versions/hardware, say so in the PR.

## Pull requests

1. Fork, branch from `main`.
2. Keep the diff focused; one logical change per PR.
3. Make sure the build is clean and the app launches.
4. Fill in the PR template (what changed, how you tested, macOS version).

By contributing you agree your work is licensed under the [MIT License](LICENSE).
