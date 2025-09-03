# Bus NavX

A Flutter mobile application for bus navigation, tracking, and attendance management with QR code scanning functionality.

## Repository

[GitHub Repository](https://github.com/fuzziecoder/Bus-NavX-App)

## Features

- **Authentication**: User login and registration system
- **Bus Navigation**: Real-time bus tracking and navigation
- **QR Attendance**: Scan QR codes to mark attendance
- **Notifications**: Receive important updates and alerts
- **User Profiles**: Manage user information and preferences
- **Comments System**: Provide feedback and communicate with others

## Prerequisites

Before running the application, make sure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=2.17.0 <3.0.0)
- [Dart SDK](https://dart.dev/get-dart) (compatible with Flutter version)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extensions
- [Git](https://git-scm.com/downloads) for version control
- A Firebase project (for authentication, database, and storage)

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/fuzziecoder/Bus-NavX-App.git
cd "Bus NavX"
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download the configuration files:
   - For Android: `google-services.json` and place it in `android/app/`
   - For iOS: `GoogleService-Info.plist` and place it in `ios/Runner/`

### 4. Enable Firebase Services

In the Firebase Console, enable the following services:
- Authentication (Email/Password)
- Cloud Firestore
- Storage
- Messaging (for notifications)

## Running the Application

### Debug Mode

```bash
flutter run
```

### Release Mode

#### Android

```bash
flutter build apk --release
```

The APK file will be available at `build/app/outputs/flutter-apk/app-release.apk`

#### iOS

```bash
flutter build ios --release
```

Then open the Xcode workspace at `ios/Runner.xcworkspace` and archive the application.

## Project Structure
