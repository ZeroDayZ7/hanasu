go get -u ./...

go run cmd/server/main.go

adb -s 5200d78bfa479449 reverse tcp:8080 tcp:8080

# ABD WIFI

adb -s 5200d78bfa479449 tcpip 5555
adb connect 100.87.236.2:5555

adb devices

5200d78bfa479449 device 17
310008a89dd353f9 unauthorized 16

.\scrcpy -s 5200d78bfa479449
.\scrcpy -s 310008a89dd353f9

flutter run
.\scrcpy -s 5200d78bfa479449 --video-buffer 2 --max-fps 60

!D/ViewR, !D/InputM, !D/InputT, !V/InputMetho, !I/InputMetho, !I/AssistStr, !D/Surf, !W/libE, !D/vndksup, !E/ViewR, !W/ViewR, !D/Profile, !I/Chor

adb -s 5200d78bfa479449 shell top

# UO

flutter build apk --release --target-platform=android-arm --dart-define=DART_VM_PRODUCT=true
flutter build apk --release --target-platform=android-arm
adb -s 5200d78bfa479449 install -r build/app/outputs/flutter-apk/app-release.apk

adb -s 5200d78bfa479449 reverse tcp:8081 tcp:8081

flutter run -d 5200d78bfa479449 --release
flutter run -d 5200d78bfa479449 --release --verbose

# Generate app icons

dart run flutter_launcher_icons:main
dart run build_runner build --delete-conflicting-outputs
dart run scripts/generate_locale_keys.dart
dart run flutter_native_splash:create

# Release

flutter build apk --obfuscate --split-debug-info=./debug_info
