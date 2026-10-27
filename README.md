# Career Buddy

**Build better habits, track focused work, and understand where your time goes.**

Career Buddy is a Flutter mobile app for personal productivity and career-oriented self-tracking. It combines timed work sessions, category-based activity tracking, analytics, goals, reminders, and Firebase-backed user accounts in one dashboard.

## Features

- **User authentication:** Register and sign in with Firebase Authentication.
- **Focus timer:** Track time spent on a selected activity category, with start, pause, stop, save, and discard controls.
- **Persistent timer state:** Store timer state locally so an in-progress session can be recovered after reopening the app.
- **Session history and analytics:** Save tracked sessions to Cloud Firestore and display activity statistics.
- **Activity calendar and streak-style tracking:** View active days based on recorded sessions.
- **Goals and reminders:** Access goal and reminder screens, including scheduled local notifications.
- **Daily check-in notification:** Schedule a recurring reminder to review your activity.
- **Interactive notification actions:** Start supported timer categories and stop/save or discard a running session from notification actions.
- **Google sign-in integration:** The project initializes Google Sign-In alongside Firebase.
- **Dark interface:** A custom dark theme, animated UI elements, and charts for activity insights.
- **AI integration foundation:** The project includes a Google Generative AI dependency and a Gemini service module.

> AI capabilities depend on the implementation and configuration in the Gemini service. Do not add API keys to source control.

## Tech Stack

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile UI |
| Dart | Application programming language |
| Firebase Core | Firebase initialization |
| Firebase Authentication | User registration, sign-in, and auth state |
| Cloud Firestore | Cloud data storage for tracked sessions and related app data |
| Riverpod | State management and dependency access |
| Shared Preferences | Local persistence for timer state |
| Awesome Notifications | Scheduled notifications and interactive notification actions |
| Flutter Local Notifications | Local notification support dependency |
| `fl_chart` | Charts and activity visualizations |
| Google Generative AI | Gemini integration |
| Google Sign-In | Google account sign-in integration |
| Google Fonts | Typography |
| Lottie | Animation support |
| `intl` | Date and time formatting |
| `flutter_dotenv` | Environment-based configuration |

## App Sections

The main dashboard navigation provides access to:

- **Home:** Overview of activity and progress.
- **Timer:** Track focused work sessions by category.
- **Stats:** Review activity analytics.
- **Alerts:** Manage reminders.
- **Profile:** View profile-related information.

The app also includes goal-management and authentication screens.

## Project Structure

The project follows a feature-oriented Flutter structure. Main areas include:

```text
career_buddy/
├── android/                  # Android platform project
├── ios/                      # iOS platform project
├── assets/
│   └── images/               # App icons, splash assets, and images
├── lib/
│   ├── main.dart             # App entry point and Firebase setup
│   ├── core/
│   │   └── theme/             # App theme
│   ├── features/
│   │   ├── auth/              # Login and registration
│   │   ├── dashboard/         # Main dashboard and navigation
│   │   ├── timer/             # Focus timer and timer state
│   │   ├── analytics/         # Statistics and charts
│   │   ├── reminders/         # Reminder interface
│   │   ├── goals/              # Goal tracking
│   │   └── profile/            # Profile interface
│   ├── services/              # Authentication, database, AI, notifications
│   └── widgets/               # Reusable UI components
├── test/                      # Flutter tests
├── pubspec.yaml               # Dependencies and asset configuration
└── firebase.json              # Firebase project tooling configuration
```

## Getting Started

### Prerequisites

Install the following tools:

- Flutter SDK (compatible with the Dart SDK constraint in `pubspec.yaml`)
- Dart SDK, included with Flutter
- Android Studio or another configured Android/iOS development environment
- A Firebase project configured for the platforms you intend to run

### 1. Clone the repository

```bash
git clone https://github.com/sarfrazcodes/career_buddy.git
cd career_buddy
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Configure Firebase for your app using the official FlutterFire setup process. Ensure the generated platform configuration, including `lib/firebase_options.dart`, is available and matches your Firebase project.

Enable Firebase Authentication providers used by the app, such as email/password and Google sign-in where configured. Configure Cloud Firestore and its security rules before using cloud-backed features.

### 4. Configure environment variables

The project loads a `.env` file at startup and declares it as an asset. Check the code in `lib/services/gemini_service.dart` to confirm the exact variable names needed for AI features.

Create the required local `.env` file if needed, but **never commit API keys or secrets**. For mobile applications, values bundled as assets can be extracted from the app, so a bundled API key should not be treated as a secure secret. For production AI calls, consider a trusted backend that keeps private credentials off the client.

### 5. Run the application

Check connected devices:

```bash
flutter devices
```

Run on a connected device or emulator:

```bash
flutter run
```

### 6. Run tests and static analysis

```bash
flutter test
flutter analyze
```

## How the Timer Works

1. Select a category for the activity.
2. Start the timer.
3. The timer updates elapsed time while running.
4. Timer state is saved locally using Shared Preferences.
5. Stop and save the session to record it for the signed-in user.
6. Review recorded activity in the dashboard and analytics screens.

The timer notification can expose actions such as stopping and saving a session or discarding it. Notification behavior can vary by operating system and permission settings.

## Data and Privacy

- Firebase Authentication manages user identity.
- Cloud Firestore stores cloud-backed activity data.
- Shared Preferences stores local timer state.
- Notification permissions are requested by the application.
- Configure Firestore security rules to restrict users to their own data.
- Do not commit `.env` files or private API credentials.
- Review the privacy implications of any AI prompts or data sent to third-party AI services.

## Troubleshooting

- **Firebase initialization errors:** Confirm Firebase is configured for the selected platform and that the generated options file is correct.
- **Sign-in errors:** Check enabled Firebase Authentication providers and the app's Google Sign-In configuration.
- **Missing AI configuration:** Verify the required `.env` variable names in the Gemini service implementation.
- **Notifications do not appear:** Check OS notification permissions and platform-specific notification configuration.
- **Cloud data does not load or save:** Verify Firestore setup, network access, and security rules.

## Contributing

1. Fork the repository.
2. Create a branch for your change.
3. Implement and test the feature.
4. Run `flutter analyze` and `flutter test`.
5. Open a pull request with a clear summary of your changes.

## License

Check the repository for a license file before reusing or redistributing the project. If no license is present, do not assume that the code is released under an open-source license.
