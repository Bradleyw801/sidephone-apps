# Sidephone apps by Brad White

An F-Droid-format repository for the Sidephone SP-01, served from GitHub Pages.
Sidephone's App Library is an F-Droid client, so this works exactly like one of
Sidephone's own App Packs: scan the QR code once, then install and update the apps
from App Library.

Install page and QR code: https://bradleyw801.github.io/sidephone-apps/

| | |
| --- | --- |
| Repository address | `https://bradleyw801.github.io/sidephone-apps/repo` |
| Fingerprint | `297A48B6E4BE5C0701771CE758E54D7885C3E342FFC46FE28247FA5038E1DAC6` |

## Apps

| App | Package | Where the build comes from |
| --- | --- | --- |
| Slickrock Station | `com.bradwhite.slickrock` | Built in the Slickrock project, APK committed here |
| RetroArch for Slickrock | `com.bradwhite.slickrock.retroarch` | Upstream RetroArch plus the patches in `source/`, APK committed here |
| Tyle | `app.tileshift` | Built in the SidePhone project, APK committed here |

## Publishing a new version

On Brad's PC, double-click `PUBLISH-TO-APP-PACK.cmd` in `Downloads\Personal\Devices\Sidephone`.
It finds the newest Slickrock Station, RetroArch for Slickrock and Tyle builds in their
usual folders, sends whatever the pack doesn't already serve, and waits until it is live.
RetroArch is GPL, so a RetroArch build goes out with its source patch: the publisher sends
the `.patch` of the same name from beside the APK (for example
`retroarch-for-slickrock-1.22.2-sr2.patch`) into `source/`.

Without it, put the APK in `fdroid/incoming/` (and a RetroArch build's patch in `source/`),
by `git push` or with "Add file, Upload files" on GitHub (up to 25 MB a file). Bigger files
go in as pieces, which the workflow joins:

```
split -b 9000000 -d -a 2 Slickrock-10.45.apk Slickrock-10.45.apk.part
```

Either way the "Publish repository" workflow vets every new build before it goes out. It
must be signed with the key pinned for that app in `fdroid/metadata/<package>.yml`
(`AllowedAPKSigningKeys`) and have a higher version code than the published build. A build
that passes replaces the old one, and the workflow signs a fresh index and deploys it with
the install page. A build that fails is deleted and the run fails, with the reason on the
run's page; everything else is still published.

Edit `fdroid/metadata/<package>.yml` only if the description should change. The name,
version and icon come from the APK and from `fdroid/metadata/<package>/en-US/icon.png`.

Phones that have the pack get the update on App Library's next refresh.

## Secrets and keys

The index is signed with `keystore.p12` (alias `sidephone`). The keystore is not in git:
the workflow restores it from the `FDROID_KEYSTORE_B64` secret and reads the passwords
from `FDROID_KEYSTORE_PASS` and `FDROID_KEY_PASS`. Keep a copy of the keystore and its
passwords outside GitHub; if the key is lost, every phone has to remove and re-add the
pack under a new fingerprint.

Each app has its own signing key, kept with that app's project. The repository key only
signs the index.

## Layout

```
fdroid/config.yml                 repository name, address, key settings (no secrets)
fdroid/metadata/<package>.yml     name, summary, description, licence, links
fdroid/metadata/<package>/en-US/icon.png
fdroid/repo/*.apk                 the apps
fdroid/incoming/                  new builds waiting to be vetted (normally empty)
site/                             install page and QR code
source/                           patches for the GPL apps carried here
tools/intake.py                   vets new builds (run by the workflow)
tools/PUBLISH-TO-APP-PACK.cmd     the PC publisher (copy of the one in Downloads\Personal\Devices\Sidephone)
tools/publish-to-app-pack.ps1     what it runs
.github/workflows/publish.yml     vets, builds the index and deploys GitHub Pages
```

## Licences

Slickrock Station and Tyle are Brad White's own apps and are not open source.
RetroArch is GPL-3.0; the changes in the build carried here are published in `source/`.
