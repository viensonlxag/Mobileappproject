@echo off
cd /d %~dp0\android

echo 🔨 Building APK...
call gradlew.bat assembleDebug

echo 📱 Installing to emulator...
E:\AndroidSDK\platform-tools\adb.exe -s emulator-5554 install -r app\build\outputs\apk\debug\app-debug.apk

echo ✅ App installed to emulator!
pause
