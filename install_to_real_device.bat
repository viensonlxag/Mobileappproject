@echo off
cd /d %~dp0\android

echo 🔨 Building APK...
call gradlew.bat assembleDebug

echo 📱 Installing to real device...
E:\AndroidSDK\platform-tools\adb.exe -s 10AE5C0ELB0010D install -r app\build\outputs\apk\debug\app-debug.apk

echo ✅ App installed to device!
pause
