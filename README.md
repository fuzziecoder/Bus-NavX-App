# Bus NavX App

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


lib/
├── app.dart                 # Main app configuration
├── config/                  # App configuration
│   ├── constants.dart       # App constants
│   ├── routes.dart          # Navigation routes
│   └── themes.dart          # App themes
├── main.dart                # Entry point
├── models/                  # Data models
├── screens/                 # App screens
│   ├── auth/                # Authentication screens
│   ├── bus_nav/             # Bus navigation screens
│   ├── comments/            # Comments screens
│   ├── dashboard/           # Main dashboard
│   ├── home/                # Home screen
│   ├── profile/             # User profile
│   ├── qr_attendance/       # QR code scanning
│   └── splash/              # Splash screen
├── services/                # Backend services
└── widgets/                 # Reusable widgets


## Dependencies

- **Firebase**: Authentication, database, storage, and messaging
- **Provider**: State management
- **Rive & Lottie**: Animations
- **Google Maps & Geolocator**: Maps and location services
- **QR Code**: QR code scanning and generation
- **UI Components**: Various UI enhancement libraries

## Troubleshooting

### Common Issues

1. **Firebase Configuration**: Ensure the Firebase configuration files are correctly placed in their respective directories.

2. **Animation Files**: If animations aren't working, check that the required files exist in:
   - `assets/animations/success.json`
   - `assets/rive/icons.riv`

3. **Permissions**: Make sure to grant location and camera permissions for the app to function properly.

### Getting Help

If you encounter any issues, please:

1. Check the [Flutter documentation](https://flutter.dev/docs)
2. Review the [Firebase documentation](https://firebase.google.com/docs)
3. Search for similar issues in the project's issue tracker
4. Open an issue in the [GitHub repository](https://github.com/fuzziecoder/Bus-NavX-App)
