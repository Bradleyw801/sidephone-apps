# Brad White's apps

These are the Android apps I have built, in one F-Droid repository. Add it to F-Droid, Droid-ify or any other
F-Droid client and you can install the apps and get their updates from there.

The install page has the QR code: https://bradleyw801.github.io/sidephone-apps/

| | |
| --- | --- |
| Address | `https://bradleyw801.github.io/sidephone-apps/repo` |
| Fingerprint | `297A48B6E4BE5C0701771CE758E54D7885C3E342FFC46FE28247FA5038E1DAC6` |

## The apps

| App | Package | What it's for |
| --- | --- | --- |
| Slickrock Station | `com.bradwhite.slickrock` | A game launcher that sets up RetroArch for you, for physical keys, a controller or a touchscreen |
| RetroArch for Slickrock | `com.bradwhite.slickrock.retroarch` | The RetroArch build Slickrock Station runs, with a few input patches |
| Tyle | `app.tileshift` | Different settings for each of the Sidephone's keypad tiles |
| Twyn Keyboard | `com.bradwhite.twyn` | A predictive keyboard for any device, built for real keys and small screens |
| Paigr Relay | `com.textrelay.relay` | Beta. Sends the texts from the phone with your SIM to your Paigr inbox |
| Paigr | `com.textrelay.texts` | Beta. Reads and answers those texts on another phone |

If you'd rather skip F-Droid, each app's current build is also at a fixed address: `slickrock.apk`, `retroarch.apk`,
`tileshift.apk`, `twyn.apk`, `relay.apk` and `texts.apk` under https://bradleyw801.github.io/sidephone-apps/. A `.json` file with
the same name has the version.

## Publishing a new version

Slickrock Station and RetroArch for Slickrock come from
[slickrock-releases](https://github.com/Bradleyw801/slickrock-releases). Publish a release there, tagged
`slickrock-<version>` or `retroarch-<version>`, with a `versionCode: N` line in the notes. The workflow looks for new
releases every hour. For RetroArch it takes the arm64-v8a APK and copies the release's `.patch` into `source/`.

Tyle, Twyn Keyboard, Paigr and Paigr Relay go in `fdroid/incoming/`, either with `git push` or with "Add file, Upload files" on
GitHub. GitHub's web upload takes files up to 25 MB. A bigger file can go in as pieces and the workflow puts them back
together:

```
split -b 9000000 -d -a 2 Paigr-Relay-1.1.apk Paigr-Relay-1.1.apk.part
```

There's also a Windows script for Tyle, `tools/PUBLISH-TO-APP-PACK.cmd`, that sends the newest build from a PC and
waits until it's live.

Every build gets checked before it goes out. It has to be signed with the key pinned for its app in
`fdroid/metadata/<package>.yml` (`AllowedAPKSigningKeys`), and its version code has to be higher than the one already
published. If it passes, it replaces the old build, and the workflow signs a new index and deploys it with the install
page. If it fails, it gets deleted and the run fails with the reason on the run's page. You can also run the workflow
by hand from the Actions tab.

The name, version and icon come from the APK and from `fdroid/metadata/<package>/en-US/icon.png`, so the `.yml` only
needs editing when the description changes. A new app needs its `.yml`, with its signing key pinned, and an icon
before its first build goes in.

Phones get the update the next time their F-Droid client refreshes.

## Keys

The index is signed with `keystore.p12` (alias `sidephone`), which isn't in git. The workflow restores it from the
`FDROID_KEYSTORE_B64` secret and reads its passwords from `FDROID_KEYSTORE_PASS` and `FDROID_KEY_PASS`. Keep a copy of
the keystore and passwords somewhere other than GitHub. If the key is ever lost, every phone has to remove the
repository and add it again with a new fingerprint.

Each app has its own signing key, kept with that app's project. The repository key only signs the index.

## What's where

```
fdroid/config.yml                 repository name, address and key settings (no secrets)
fdroid/metadata/<package>.yml     each app's name, summary, description, licence and pinned key
fdroid/metadata/<package>/en-US/icon.png
fdroid/repo/*.apk                 the apps
fdroid/incoming/                  new builds waiting to be checked (normally empty)
site/                             the install page and QR code
source/                           patches for the GPL apps served here
licenses/                         licences for code the apps include
tools/intake.py                   checks new builds (the workflow runs it)
tools/PUBLISH-TO-APP-PACK.cmd     sends a new Tyle build from a Windows PC
tools/publish-to-app-pack.ps1     the script it runs
.github/workflows/publish.yml     fetches Slickrock releases, checks new builds, signs the index and deploys the site
```

## Licences

Slickrock Station, Tyle and Twyn Keyboard are my own apps and aren't open source. Twyn Keyboard's English word data
comes from the Leipzig Corpora Collection (CC BY 4.0), Traditional T9's word list (Apache 2.0, built on SCOWL) and the
UCI SMS Spam Collection (CC BY 4.0); the notices are in the app. Paigr and Paigr Relay are open source under the
Apache License 2.0, at [Bradleyw801/Paigr](https://github.com/Bradleyw801/Paigr). Both include Java-WebSocket (MIT,
`licenses/Java-WebSocket.txt`) and ZXing (Apache 2.0, `licenses/ZXing.txt`). RetroArch is GPL-3.0, and my changes to
the build served here are in `source/`.
