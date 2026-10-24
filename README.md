# Brad White's apps

An F-Droid-format repository, served from GitHub Pages, for every app Brad White publishes.
Scan the QR code once in F-Droid, Droid-ify or the Sidephone's App Library (an F-Droid
client), then install and update the apps from there.

Install page and QR code: https://bradleyw801.github.io/sidephone-apps/

| | |
| --- | --- |
| Repository address | `https://bradleyw801.github.io/sidephone-apps/repo` |
| Fingerprint | `297A48B6E4BE5C0701771CE758E54D7885C3E342FFC46FE28247FA5038E1DAC6` |

The address keeps its old name so the Sidephones that already have it keep working.

## Apps

| App | Package | Where the build comes from |
| --- | --- | --- |
| Slickrock Station | `com.bradwhite.slickrock` | The newest release of [slickrock-releases](https://github.com/Bradleyw801/slickrock-releases), fetched by the workflow |
| RetroArch for Slickrock | `com.bradwhite.slickrock.retroarch` | The arm64-v8a build of the newest release of [slickrock-releases](https://github.com/Bradleyw801/slickrock-releases), with its patch in `source/` |
| Tyle | `app.tileshift` | Built in the Sidephone project, sent with `PUBLISH-TO-APP-PACK.cmd` |
| Paigr Relay | `com.textrelay.relay` | Built in the Paigr project, put in `fdroid/incoming/` |
| Paigr | `com.textrelay.texts` | Built in the Paigr project, put in `fdroid/incoming/` |

Paigr Relay goes on the phone that keeps the SIM and Google Messages; Paigr on the phone
you carry. Setting up takes one scan: Paigr Relay shows a code when it opens, and Paigr
scans it (Scan code). The two phones get their own private, end-to-end encrypted inbox on the shared
server, with no account or password. Reactions, quoted replies and attachments work both ways: they travel as the
texts and files Messages already understands, and attachments sent from Paigr go out from the relay phone as MMS
when Messages won't take them itself. Both apps can connect through Tor, with Orbot. More devices join with Paigr Relay's Link a device; a
new relay phone takes over when the linked Paigr scans its code; and reinstalled on the same
phone, either app gets back in by itself.

The current build of each app is also at a fixed address for direct download, with its
version in a `.json` of the same name: `slickrock.apk`, `retroarch.apk`, `tileshift.apk`,
`relay.apk` and `texts.apk` under https://bradleyw801.github.io/sidephone-apps/.

## Publishing a new version

- **Slickrock Station and RetroArch for Slickrock:** publish a release on
  slickrock-releases (tag `slickrock-<version>` or `retroarch-<version>`, notes with a
  `versionCode: N` line). The "Publish repository" workflow checks those releases every
  hour and on every run, and takes the newest build the pack does not already serve. For
  RetroArch it takes the arm64-v8a APK and the release's `.patch` into `source/`.
- **Tyle:** on Brad's PC, double-click `PUBLISH-TO-APP-PACK.cmd` in
  `Downloads\Personal\Devices\Sidephone`. It finds the newest Tyle build, sends it if the
  pack doesn't already serve it, and waits until it is live.
- **Paigr, Paigr Relay, or by hand:** put the APK in `fdroid/incoming/`, by `git push` or with
  "Add file, Upload files" on GitHub (up to 25 MB a file). Bigger files go in as pieces,
  which the workflow joins:

  ```
  split -b 9000000 -d -a 2 Paigr-Relay-1.1.apk Paigr-Relay-1.1.apk.part
  ```

Every new build is vetted before it goes out. It must be signed with the key pinned for
that app in `fdroid/metadata/<package>.yml` (`AllowedAPKSigningKeys`) and have a higher
version code than the published build. A build that passes replaces the old one, and the
workflow signs a fresh index and deploys it with the install page. A build that fails is
deleted and the run fails, with the reason on the run's page; everything else is still
published. The workflow can also be started by hand from the Actions tab.

Edit `fdroid/metadata/<package>.yml` only if the description should change. The name,
version and icon come from the APK and from `fdroid/metadata/<package>/en-US/icon.png`.
A new app needs its own `fdroid/metadata/<package>.yml` with its signing key pinned, and
its icon, before its first build is sent.

Phones that have the repository get each update on their F-Droid client's next refresh.

## Secrets and keys

The index is signed with `keystore.p12` (alias `sidephone`). The keystore is not in git:
the workflow restores it from the `FDROID_KEYSTORE_B64` secret and reads the passwords
from `FDROID_KEYSTORE_PASS` and `FDROID_KEY_PASS`. Keep a copy of the keystore and its
passwords outside GitHub; if the key is lost, every phone has to remove and re-add the
repository under a new fingerprint.

Each app has its own signing key, kept with that app's project. The repository key only
signs the index.

## Layout

```
fdroid/config.yml                 repository name, address, key settings (no secrets)
fdroid/metadata/<package>.yml     name, summary, description, licence, pinned signing key
fdroid/metadata/<package>/en-US/icon.png
fdroid/repo/*.apk                 the apps
fdroid/incoming/                  new builds waiting to be vetted (normally empty)
site/                             install page and QR code
source/                           patches for the GPL apps carried here
licenses/                         licences of code the apps include
tools/intake.py                   vets new builds (run by the workflow)
tools/PUBLISH-TO-APP-PACK.cmd     the PC publisher for Tyle (copy of the one in Downloads\Personal\Devices\Sidephone)
tools/publish-to-app-pack.ps1     what it runs
.github/workflows/publish.yml     fetches Slickrock releases, vets, builds the index and deploys GitHub Pages
```

## Licences

Slickrock Station, Tyle, Paigr and Paigr Relay are Brad White's own apps and are not open
source. RetroArch is GPL-3.0; the changes in the build carried here are published in
`source/`. Paigr and Paigr Relay include Java-WebSocket, under the MIT licence in
`licenses/Java-WebSocket.txt`, and ZXing's QR code library, under the Apache License 2.0 in
`licenses/ZXing.txt`.
