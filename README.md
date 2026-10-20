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
| RetroArch for Slickrock | `com.bradwhite.slickrock.retroarch` | RetroArch 1.22.2 plus the patch in `source/`, APK committed here |
| Tyle | `app.tileshift` | Built in the SidePhone project, APK committed here |

## Publishing a new version

1. Put the new APK in `fdroid/repo/` and remove the old one. It must be signed with the
   same key as the version already there, or phones will refuse the update. Any way of
   getting the file into the repository works: `git push`, or "Add file, Upload files"
   on GitHub. If an upload tool cannot take the whole file, split it and drop the pieces
   in `fdroid/incoming/` instead:

   ```
   split -b 9m -d --additional-suffix= Slickrock-10.45.apk Slickrock-10.45.apk.part
   ```

   The workflow joins the pieces, moves the APK into `fdroid/repo/` and commits it.
2. Edit `fdroid/metadata/<package>.yml` if the description should change. The name,
   version and icon come from the APK and from `fdroid/metadata/<package>/en-US/icon.png`.
3. Push. The "Publish repository" workflow signs a fresh index and deploys it with the
   install page.

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
fdroid/incoming/                  split APK pieces waiting to be joined (normally empty)
site/                             install page and QR code
source/                           patches for the GPL apps carried here
.github/workflows/publish.yml     builds the index and deploys GitHub Pages
```

## Licences

Slickrock Station and Tyle are Brad White's own apps and are not open source.
RetroArch is GPL-3.0; the changes in the build carried here are published in `source/`.
