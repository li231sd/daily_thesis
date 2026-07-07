# Daily Thesis

A Flutter app that delivers one relevant research paper a day, picked to match your interests.

On first launch you pick a set of subjects (Computer Science, Medicine, Biology, Physics, Mathematics, Economics, Psychology, Chemistry, and more). From then on, the app pulls a matching paper each day from a Cloudflare Worker backend, which sources papers from arXiv and OpenAlex. You can read the abstract, jump to the full paper, and browse your past reading history.

## Features

- **Onboarding** — select the subjects you care about; this drives which papers you're shown
- **Daily paper** — a new paper surfaced each day based on your interests
- **History** — browse papers you've previously seen
- **Settings** — update your subjects or preferences at any time
- **Share** — send a paper to someone else via the OS share sheet
- **Ads** — the app is free to use and supported by AdMob banner and interstitial ads

## Tech stack

- **Flutter / Dart** (Dart SDK `^3.12.2`)
- **Backend**: a Cloudflare Worker that queries arXiv and OpenAlex and returns matched papers
- **Local storage**: `shared_preferences` for user profile, subjects, and reading history
- **Ads**: `google_mobile_ads` (AdMob), configured via `flutter_dotenv`
- Other notable packages: `http`, `xml` (parsing arXiv's XML feed), `url_launcher`, `share_plus`

Supported platforms: Android, iOS, and web/desktop (Windows, macOS, Linux) via Flutter's standard multi-platform support — ads currently only run on Android/iOS.

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and on your `PATH`
- An Android emulator, iOS simulator, or physical device (`flutter devices` to check what's available)

### Setup

1. Clone the repo and install dependencies:
   ```bash
   flutter pub get
   ```

2. Create a `.env` file in the project root (see `.env.example`) with your AdMob credentials:
   ```dotenv
   ADMOB_APP_ID="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"
   PaperScreen_Banner="ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
   PaperScreen_Interstitial="ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy"
   ```
   The same `ADMOB_APP_ID` value must also be set as the `com.google.android.gms.ads.APPLICATION_ID` meta-data value in `android/app/src/main/AndroidManifest.xml` (this is required at build time and can't be read from `.env`).

   While developing, you can use [Google's official test ad unit IDs](https://developers.google.com/admob/android/test-ads) instead of real ones to avoid triggering invalid traffic on your AdMob account.

3. Run the app:
   ```bash
   flutter run
   ```

### Building a release APK
```bash
flutter build apk --release
```
Output lands at `build/app/outputs/flutter-apk/app-release.apk`.

## Project structure

```
lib/
├── main.dart                    # App entry point; loads .env, initializes ads
├── models/                      # Data models (e.g. UserProfile)
├── screens/
│   ├── onboarding_screen.dart    # First-run subject selection
│   ├── paper_screen.dart         # Main daily paper view + banner/interstitial ads
│   ├── history_screen.dart       # Past papers
│   └── settings_screen.dart      # Update subjects/preferences
├── services/
│   ├── paper_service.dart        # Fetches papers from the backend
│   ├── interest_matcher.dart     # Maps UI subjects to backend subject keys
│   ├── profile_storage.dart      # Persists user profile
│   ├── paper_history_storage.dart# Persists reading history
│   ├── theme_mode_storage.dart   # Persists light/dark mode preference
│   └── ad_service.dart           # AdMob initialization and ad loading
└── widgets/
    └── banner_ad_widget.dart     # Reusable banner ad widget
```

## Notes for contributors

- `.env` is gitignored — never commit real AdMob IDs. Use `.env.example` as the template.
- Android signing keys (`key.properties`, `*.jks`/`*.keystore`) are also gitignored; keep them out of version control.
- This project is a Flutter starting point extended with a custom backend and monetization — see [Flutter's docs](https://docs.flutter.dev/) for general framework guidance if you're new to Flutter itself.
