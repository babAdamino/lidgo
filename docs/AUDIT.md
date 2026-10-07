# Audit & verify lidgo

lidgo asks for a narrow slice of root, so it should be easy to check, not taken on
faith. This page shows you how to confirm what it does yourself and how
to verify a download you did not build.

There is no Apple account behind any of this. Every check below is free and runs on your
machine.

## Reporting a vulnerability

Do not open a public issue. On the
[Security tab](https://github.com/babadamino/lidgo/security), choose
**Advisories → Report a vulnerability** to open a private draft visible only to
you and the maintainer. Include the exact macOS version, what you did, and what
you expected. You will get a response, and the fix is credited in the release
notes unless you prefer to stay anonymous.

## Read it in about ten minutes

The whole app is one file. To satisfy yourself it does what it claims and nothing else:

| Read | What you are checking |
|---|---|
| [`App.swift`](../App.swift) | The only thing it runs as root is `sudo -n /usr/bin/pmset -a disablesleep 0/1` (`setDisableSleep`). No network calls, no file writes outside `UserDefaults`, no shell strings. |
| [`lidgo.sudoers.template`](../lidgo.sudoers.template) / [`grant.sh`](../grant.sh) | The passwordless grant permits exactly those two fully-specified commands, no wildcards, installed `root:wheel 0440`. |
| [`build.sh`](../build.sh) | `swiftc` + a hand-assembled, ad-hoc-signed bundle. No downloaded blobs, no install-time scripts baked into the binary. |
| [`uninstall.sh`](../uninstall.sh) | Removes the app, the login item, and the sudoers drop-in, then proves `sudo -n pmset …` prompts again. |

The single privileged file on your system is `/etc/sudoers.d/lidgo-disablesleep`. Read
it, and `sudo rm` it any time to revoke everything.

## Verify a release you downloaded (did not build)

Releases are built on a GitHub-hosted runner and published with checksums.
One check, offline-friendly:

```sh
# Integrity: the bytes match what the release published.
shasum -a 256 -c SHA256SUMS
```

What it proves: the file was not altered after publishing. It says nothing
about *who* built it. For the stronger link from "the source you can read"
to "the binary you ran," rebuild from source below and compare — that is
the check that needs no trust in the runner.

## Reproduce the build

The compile is deterministic for a given toolchain, so you can rebuild and compare the
**unsigned executable** byte for byte:

```sh
git clone https://github.com/babadamino/lidgo.git
cd lidgo && git checkout v<version>

# Rebuild the executable with the release's deployment target.
swiftc -O -parse-as-library -target arm64-apple-macos13.0 \
  -framework AppKit -framework ServiceManagement App.swift -o /tmp/lidgo-rebuilt

# Unzip the release and compare the Mach-O inside the bundle.
ditto -x -k lidgo-<version>.zip /tmp/rel
shasum -a 256 /tmp/lidgo-rebuilt /tmp/rel/lidgo.app/Contents/MacOS/lidgo
```

Caveats, stated honestly:

- The two hashes match **only with the same Swift/Command Line Tools version** used by the
  release runner (`macos-latest`). A different compiler version will produce a different,
  still-correct binary. The release job prints its toolchain in the **Toolchain** step so you
  can match it.
- The **signed** `.app` is only *likely* reproducible: ad-hoc code signatures embed
  non-deterministic data, so compare the unsigned Mach-O above, not the signed bundle. See
  the [Reproducible Builds definition](https://reproducible-builds.org/docs/definition/).

For most people the checksum + a source rebuild is the practical guarantee;
reproducing the build is the deepest check if you want it.

## Scan it with VirusTotal

You can upload the release zip to [VirusTotal](https://www.virustotal.com) (free,
non-commercial, results public) for a multi-engine scan:

```sh
# With a free VirusTotal API key:
curl -s --request POST --url https://www.virustotal.com/api/v3/files \
  --header "x-apikey: $VT_API_KEY" \
  --form file=@lidgo-<version>.zip
# …then open the returned analysis URL, or just drag the zip onto virustotal.com.
```

Note: ad-hoc-signed, unnotarized binaries draw more *heuristic* flags than notarized ones, so
read any detection in context. A clean result is reassuring, not absolute; pair it with the
checksum + rebuild above.

## Notarization (planned, not yet done)

lidgo is ad-hoc signed and **not notarized** today, because notarization needs a paid
Apple Developer ID. It is on the roadmap. The exact steps, for transparency and so anyone can
do it from a fork, are:

```sh
# One-time: store an app-specific password for notarytool.
xcrun notarytool store-credentials "notarytool-password" \
  --apple-id "<apple-id>" --team-id <TeamID> --password <app-specific-password>

# Re-sign with a Developer ID cert + hardened runtime + secure timestamp.
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: <Name> (<TeamID>)" lidgo.app

ditto -c -k --keepParent lidgo.app lidgo.zip
xcrun notarytool submit lidgo.zip --keychain-profile "notarytool-password" --wait
xcrun stapler staple lidgo.app
```

Prerequisite: [Apple Developer Program, $99/yr](https://developer.apple.com/programs/whats-included/),
and a "Developer ID Application" certificate. Notarization removes the
"Apple could not verify this app" first-launch block; it does not change anything about how
the app works. The `/etc/sudoers.d` install step is what makes lidgo ineligible for the
Mac App **Store**, but it does not block notarized *direct* distribution (notarization is an
automated malware scan, not a behavioral policy review).
