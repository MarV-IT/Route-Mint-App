# MarV Route

Flutter application for recording trips, mileage, fuel and expenses, with PDF/CSV reports and Firebase account backup.

## Development

- Flutter **3.47.2**, pinned in CI.
- Android **7.0 / API 24+**; compile/target API 36 with this SDK.
- iOS **15+**; native builds require macOS, Xcode and CocoaPods.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

On macOS, check native iOS compilation with `flutter build ios --release --no-codesign`. For a physical iPhone, open `ios/Runner.xcworkspace` and select your Apple development team and signing profile. The bundle identifier on both platforms is `com.marvroute.app`.

Firebase initializes from `lib/firebase_options.dart`; Android also uses `android/app/google-services.json`. Keep these and `firebase.json` consistent when reconfiguring Firebase. Cloud access depends on the project's deployed authentication settings and Firestore rules.

Android release signing uses local `android/key.properties` when present. Without it, builds use a debug key for local/CI verification; store distribution requires release credentials.

CI checks analysis/tests, an Android release APK and an unsigned iOS release build. See [MOBILE_QA.md](MOBILE_QA.md) for device acceptance steps and verification limits.
