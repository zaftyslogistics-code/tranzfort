# Checklist - Debug APK + New Image Assets

## 1) Asset Intake
- [x] Locate newly added image files in workspace
- [x] Confirm files copied under `TranZfort/assets/images/`
  - [x] `icon.png`
  - [x] `main-logo-transparent.png`
  - [x] `splash-screen-logo.png`

## 2) Code Wiring
- [x] Register `assets/images/` in `TranZfort/pubspec.yaml`
- [x] Use `splash-screen-logo.png` on splash screen
- [x] Use `main-logo-transparent.png` on splash screen
- [ ] Apply `icon.png` as launcher icon resources (optional next step)

## 3) Build Validation
- [x] `flutter pub get`
- [x] `flutter analyze`
- [x] Build debug APK (`flutter build apk --debug`)
- [x] Confirm output file exists in `build/app/outputs/flutter-apk/`

## 4) Handover
- [x] Share APK path
- [x] Share any pending item(s)
