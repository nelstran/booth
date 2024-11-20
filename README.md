# Booth Application
Booth is a cross-platform mobile application built with Flutter, designed for both Android and iOS platforms. The app utilizes Google Firebase for database storage, file storage, and user authentication, which provide backend support for features like user profiles, session management, image sharing, and friend interactions within the application. 

# Prerequisites - Before building the app, install the following:
- Flutter SDK:
  Download the Flutter SDK from the official site.
  Ensure you add Flutter to your system's PATH.
  Run flutter doctor to verify your installation.
  Dart SDK: Installed automatically with Flutter.

- Development Tools:
  Install Android Studio: Includes Android SDK and emulator for testing Android apps.
  Install Xcode (Mac only): Get it from the Mac App Store for iOS development.
  Connect a physical device via USB or set up an emulator in AS/Xcode.

- Firebase Setup
  Enter the Firebase console and download the necessary configuration files:
    Android: google-services.json → Place it in the android/app directory.
    iOS: GoogleService-Info.plist → Place it in the ios/Runner directory.
  Enable Firebase services in the Firebase console:
    Authentication
    Realtime Database
    Storage

# Build the Project
- Clone the repository:
  git clone https://capstone-cs.eng.utah.edu/booth/booth.git
  cd booth  
- Install dependencies:
  flutter pub get  

# Run the Application:
- For Android (Windows/Linux/Mac):
  flutter run --target-platform android-arm64  

- For iOS (Mac only):
  flutter run --target-platform ios-arm64  

# Building Release Versions
- Android:
  flutter build apk --release  

- iOS (Mac only):
  flutter build ios --release  

# Common Errors on Mac (CocoaPods Issues)
You might encounter CocoaPods-related errors when building for iOS on macOS.To resolve these:
- Install CocoaPods:
  sudo gem install cocoapods  
  pod setup  

- If errors persist, run:
  pod install --repo-update  

- For detailed troubleshooting, refer to the CocoaPods installation guide.

# Platforms
- Android: Requires Android 5.0 (API level 21) or higher.
- iOS: Requires iOS 12.0 or higher.
