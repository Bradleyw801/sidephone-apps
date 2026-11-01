# Brad White's Sidephone apps

The apps I have built for the Sidephone, in one F-Droid repository. Add it to the Sidephone's App Library (it is an
F-Droid client), F-Droid or Droid-ify and you can install them and get their updates from there.

My other apps, Slickrock Station, RetroArch for Slickrock, Twyn Keyboard, Paigr and Paigr Relay, moved to
[Brad White's apps](https://bradleyw801.github.io/apps/) on 1 Nov 2026. Add that repository the same way and their
updates carry on from there.

The install page has the QR code: https://bradleyw801.github.io/sidephone-apps/

| | |
| --- | --- |
| Address | `https://bradleyw801.github.io/sidephone-apps/repo` |
| Fingerprint | `297A48B6E4BE5C0701771CE758E54D7885C3E342FFC46FE28247FA5038E1DAC6` |

## The apps

| App | Package | What it's for |
| --- | --- | --- |
| Tyle | `app.tileshift` | Different settings for each of the Sidephone's keypad tiles |

If you'd rather skip F-Droid, the current build is also at a fixed address, `tileshift.apk` under
https://bradleyw801.github.io/sidephone-apps/. A `.json` file with the same name has the version.

## Publishing a new version

A new Tyle build goes in `fdroid/incoming/`, either with `git push` or with "Add file, Upload files" on GitHub.
GitHub's web upload takes files up to 25 MB. A bigger file can go in as pieces and the workflow puts them back
together:

```
split -b 9000000 -d -a 2 Tyle-1.23.apk Tyle-1.23.apk.part
```

There's also a Windows script, `tools/PUBLISH-TO-APP-PACK.cmd`, that sends the newest build from a PC and waits until
it's live.

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
tools/intake.py                   checks new builds (the workflow runs it)
tools/PUBLISH-TO-APP-PACK.cmd     sends a new Tyle build from a Windows PC
tools/publish-to-app-pack.ps1     the script it runs
.github/workflows/publish.yml     checks new builds, signs the index and deploys the site
```

## Licences

Tyle is my own app and isn't open source.
