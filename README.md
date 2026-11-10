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

## Legal and tax wording

- **Documents.** The Privacy Policy and Terms of Service live on marvroute.com (`LegalLinks`). The app links to them from the sign-in screen and from Profile → Privacy & Data, with `?lang=` so French and Ukrainian users get their own version. Keep the documents, the store data-safety forms and the app in step: change the policy first when the app starts collecting something new.
- **Location.** `requestLocationWithDisclosure` explains the use of location before the system prompt appears. Do not call `LocationPermissionService.checkAndRequest` directly from a screen.
- **Deduction.** Only the United States has a standard mileage rate a self-employed driver can deduct, so only US users see an amount, always labelled as an estimate (`TaxService.showsDeductionEstimate`). For Canada the app keeps the kilometer log and shows no amount: the CRA per-kilometre figures are employer allowance limits, not a deduction.
- **Licenses.** Profile → About → Open-source licenses shows the notices of the bundled packages.

CI checks analysis/tests, an Android release APK and an unsigned iOS release build. See [MOBILE_QA.md](MOBILE_QA.md) for device acceptance steps and verification limits.
