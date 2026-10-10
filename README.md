# IOS-26-clock-on-ios-15-flutter-app

A lightweight, dark Cupertino stopwatch screen built with Flutter.

## Run

```sh
flutter pub get
flutter run
```

## iOS 15 build

The **iOS build** GitHub Actions workflow generates the iOS project, sets the
deployment target to iOS 15, analyzes the Dart code, and builds an unsigned
arm64 iOS app suitable for devices such as the iPhone SE (1st generation). It
packages the app as `Runner.ipa`, with `Payload/Runner.app` at the archive root.
Download and extract the `ios-15-iphone-se-unsigned-ipa` artifact from a
successful workflow run to get the IPA file. The IPA is unsigned; installing it
through normal iOS distribution requires signing with an Apple developer
certificate.
