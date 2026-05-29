@echo off
REM Build script for TranZfort APK with environment variables
REM Usage: build-apk.bat

echo Building TranZfort APK with environment variables...

cd TranZfort

flutter build apk ^
  --dart-define=SUPABASE_URL=https://jgtgdfhdtjhidywpautk.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpndGdkZmhkdGpoaWR5d3BhdXRrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIwMjk3NDIsImV4cCI6MjA4NzYwNTc0Mn0.FJ0V9Wnr1fCH1FEJXX60IYkvSFKTA8sdoJ4QSdMGPDc ^
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSyCZJT8NoW2LqlM8qaubd3dfOeXOuTn6LVQ ^
  --dart-define=GOOGLE_WEB_CLIENT_ID=87956220473-fo2gcntk9p05ttp0shb8bta7997emm8l.apps.googleusercontent.com

echo.
echo APK build complete!
echo Location: build\app\outputs\flutter-apk\app-release.apk
