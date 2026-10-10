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
arm64 iOS app suitable for devices such as the iPhone SE (1st generation).
Download the `ios-15-iphone-se-unsigned` artifact from a successful workflow
run. Installing it on a device requires signing with an Apple developer
certificate.
