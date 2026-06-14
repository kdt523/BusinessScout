# B Scout Google Play Assets

Generated brand files:

- `app_icon_512.png` - Google Play store app icon, 512 x 512 PNG with alpha.
- `feature_graphic_1024x500.png` - Google Play feature graphic, 1024 x 500 PNG without alpha.
- `b_scout_logo_wordmark_1024x256.png` - Transparent brand wordmark for store/press use.
- `../assets/brand/b_scout_icon_master_1024.png` - High-resolution master launcher icon.

Android launcher files already installed:

- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `android/app/src/main/res/mipmap-*/ic_launcher_round.png`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- `android/app/src/main/res/drawable/ic_launcher_foreground.png`

Google Play listing checklist:

- App name: `B Scout` (30 character limit).
- Package name: `com.zraldwebdevelopmentservices.businessideas` (permanent once uploaded).
- App icon: 512 x 512, 32-bit PNG with alpha, max 1024 KB.
- Feature graphic: 1024 x 500, JPEG or 24-bit PNG, no alpha.
- Screenshots: at least 2 total; JPEG or 24-bit PNG, no alpha, min 320 px, max 3840 px.
- Short description: max 80 characters.
- Full description: max 4000 characters.
- Contact email: required in Play Console.
- Release artifact: upload `build/app/outputs/bundle/release/app-release.aab`.
- Before production upload, replace debug signing with a real release keystore and complete Play Console declarations: Data safety, content rating, target audience, ads, privacy policy, and app access.
