# Building from source

## Requirements

1. Requires a working instance of [Flutter](https://docs.flutter.dev/get-started/install).

2. Linux requires `libappindicator` and `keybinder`.
    
    Fedora:

    ```
    sudo dnf install libappindicator-gtk3 libappindicator-gtk3-devel keybinder keybinder3 keybinder3-devel
    ```

    Ubuntu:

    ```
    sudo apt-get install appindicator3-0.1 libappindicator3-dev keybinder-3.0
    ```


## Build

Run these commands from the root directory of the repo:

1. `flutter clean`
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter pub run easy_localization:generate --source-dir translations --output-dir lib/generated --output-file locale_keys.g.dart --format keys --skip-unnecessary-keys`
5. Run the build command for the desired platform(s):
 - `flutter build linux`
 - `flutter build windows`
 - `flutter build apk`
 - `flutter build appbundle`


Compiled app location:

Linux: `build/linux/x64/release/bundle`

Windows: `build\windows\runner\Release`

Android APK: `build/app/outputs/flutter-apk/app-release.apk`

Android App Bundle: `build/app/outputs/bundle/release/app-release.aab`
