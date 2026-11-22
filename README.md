# Pizza Planet — cartoon pizza GPS map

An iOS 16+ SwiftUI and MapKit app. It displays your live location, searches Apple Maps for pizza restaurants, hides Apple's ordinary point-of-interest pins, and uses cartoon pizza-slice markers. Tap a pizza to see its address and launch driving directions. The custom yellow-and-red UI gives the map a pizza-world theme while leaving real roads readable.

## Building an IPA for KravaSign using only an iPad

This ZIP is an Xcode source project, **not an IPA**. It includes `.github/workflows/build-ipa.yml`, a GitHub Actions cloud-Mac workflow that compiles an unsigned IPA.

1. In the iPad Files app, unzip this download and open the `KravaSign` folder.
2. In Safari, create a GitHub repository (public repositories have free standard macOS Actions minutes). GitHub's web uploader may not preserve a hidden `.github` folder from iPad Files: upload the visible `KravaSign` Swift files and `KravaSign.xcodeproj` project contents while preserving their directory paths, or use a Git client that supports folder upload. On GitHub, create `.github/workflows/build-ipa.yml` if it was not uploaded, by copying the included file.
3. Open **Actions → Build Pizza Planet IPA → Run workflow** on GitHub.
4. Once the build succeeds, open the run and download the **PizzaPlanet-unsigned-IPA** artifact. GitHub will deliver a ZIP containing `PizzaPlanet-unsigned.ipa`; unzip it using Files.
5. Import `PizzaPlanet-unsigned.ipa` into KravaSign; sign it with your eligible certificate and install.

The IPA is unsigned until KravaSign signs it. The app does not include a certificate. It requires GPS permission and internet access for Apple Maps search. Search results may not include every pizza shop; unrelated listings are filtered out. The workflow has not been tested on GitHub's macOS runner yet.
