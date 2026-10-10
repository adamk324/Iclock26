# Clock*

A LightWeight IOS 15 Clock inspirated by IOS 26-27.

## Features

### Nightstand

Nightstand mode inspirated from ios 18 nightstand mode.

![Nightstand clock](Docs/Screenshoots/NS.png)
![Nightstand red mode](Docs/Screenshoots/NS2.png)

### Alarms

Simple Alarms, with the defauld ios notification sound.

![Alarm screen](Docs/Screenshoots/Alarm.png)

### Stopwatch

Stopwatch. just how you like it.

![Stopwatch screen](Docs/Screenshoots/Stopwatch.png)
![Stopwatch laps](Docs/Screenshoots/Stopwatch2.png)

### World Clock

Drift around the world, Just only in time.

![World Clock screen](Docs/Screenshoots/WorldClock.png)


### Personalization

Personalize your app, Your way! Supports Accent Colours and Haptic Feadbacks (Only Works on Phones With Taptic Engine!)

![Personalization settings](Docs/Screenshoots/Personalisation.png)



## iOS 15 build

The GitHub Actions workflow builds an unsigned iOS 15 IPA and checks the Dart
code with `flutter analyze`. To run it manually, open **Actions → iOS build →
Run workflow**. When it completes, download the `ios-15-unsigned-ipa` artifact.
The IPA inside is named `Clock.ipa`.

The IPA is unsigned. Installing it through normal iOS distribution requires
signing it with an Apple developer certificate.
