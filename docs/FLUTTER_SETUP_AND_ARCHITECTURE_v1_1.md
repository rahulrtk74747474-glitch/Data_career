# DataQuest v1.1 — Flutter Setup, Architecture, Theme and Navigation

Status: **Expansion Item 2**
Base package: `dataquest_analyst_career`
Current app version: **1.1.0+11**
Target: Android-first, offline-first, low-end-device friendly.

---

# 1. What this document covers

This is the setup-from-scratch guide for contributors who want to run DataQuest using either:

1. **Android Studio on a local computer**, or
2. **GitHub Codespaces in a browser**.

It also documents:
- the current Flutter package dependencies;
- the clean feature-oriented folder structure;
- light/dark theming;
- named navigation;
- the startup splash flow;
- exact analyze/test/build commands;
- release artifact commands.

DataQuest v1.1 preserves all v1.0 player data and migrations.

---

# 2. Prerequisites

## 2.1 Required tools

For local Android development install:

- Git
- Flutter stable channel
- Dart (bundled with Flutter)
- Android Studio
- Android SDK
- Android SDK Platform Tools
- Android SDK Command-line Tools
- Java 17
- one Android emulator or a physical Android device with USB debugging enabled

Check all tools with:

```bash
git --version
flutter --version
dart --version
java -version
flutter doctor -v
```

The most important command is:

```bash
flutter doctor -v
```

Resolve every Android toolchain error before building the app.

---

# 3. Android Studio setup from a blank machine

## Step 1 — Install Flutter

Follow the Flutter stable installation for your operating system and add the Flutter `bin` directory to PATH.

Then run:

```bash
flutter channel stable
flutter upgrade
flutter doctor -v
```

## Step 2 — Install Android Studio

In Android Studio install:
- Android SDK;
- Android SDK Platform Tools;
- Android SDK Build Tools;
- Android SDK Command-line Tools;
- an Android platform supported by the current Flutter stable release.

Open:

**Android Studio → Settings/Preferences → Languages & Frameworks → Android SDK**

Install the missing packages shown by `flutter doctor -v`.

Accept Android licenses:

```bash
flutter doctor --android-licenses
```

Then verify:

```bash
flutter doctor -v
```

## Step 3 — Clone DataQuest

```bash
git clone https://github.com/rahulrtk74747474-glitch/Data_career.git
cd Data_career
```

## Step 4 — Generate the Android platform wrapper

The repository keeps the Flutter application source in Git and can regenerate the Android wrapper.

Run:

```bash
flutter create \
  --platforms=android \
  --project-name dataquest_analyst_career \
  --org com.dataquest \
  .
```

## Step 5 — Apply DataQuest Android configuration

This configures:
- Android notification receivers;
- notification reboot handling;
- Internet permission for optional online features;
- core-library desugaring;
- Java 17;
- multidex support.

Run:

```bash
dart run tool/configure_android_notifications.dart
```

## Step 6 — Install Dart/Flutter packages

```bash
flutter pub get
```

## Step 7 — Verify the project

```bash
flutter analyze
flutter test
```

## Step 8 — Start a device

List available targets:

```bash
flutter devices
```

For an Android emulator, create/start one from Android Studio Device Manager.

For a physical phone:
1. enable Developer Options;
2. enable USB Debugging;
3. connect by USB;
4. accept the debugging prompt;
5. run `flutter devices`.

## Step 9 — Run DataQuest

```bash
flutter run
```

Choose a specific device:

```bash
flutter run -d DEVICE_ID
```

---

# 4. GitHub Codespaces setup

Codespaces is useful for coding, tests and Android artifact builds without installing Flutter locally.

## Step 1 — Open the repository

Open:

`https://github.com/rahulrtk74747474-glitch/Data_career`

Choose:

**Code → Codespaces → Create codespace on main**

## Step 2 — Install Flutter stable if the Codespace image does not already contain it

From the Codespaces terminal:

```bash
cd /workspaces
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter-sdk
echo 'export PATH="/workspaces/flutter-sdk/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter --version
dart --version
```

If the repository was opened directly as the Codespace workspace, return to it:

```bash
cd /workspaces/Data_career
```

## Step 3 — Install Android/Java requirements when needed

Verify:

```bash
java -version
flutter doctor -v
```

Codespaces is primarily recommended for:
- editing;
- `flutter analyze`;
- unit/widget tests;
- CI-style Android artifact builds.

A browser Codespace is not the best environment for an interactive Android emulator. Use the CI artifacts or a physical/local Android device for actual gameplay testing.

## Step 4 — Bootstrap DataQuest

```bash
flutter create \
  --platforms=android \
  --project-name dataquest_analyst_career \
  --org com.dataquest \
  .

dart run tool/configure_android_notifications.dart
flutter pub get
flutter analyze
flutter test
```

## Step 5 — Build Android artifacts

Debug APK:

```bash
flutter build apk --debug
```

Release Android App Bundle:

```bash
flutter build appbundle --release
```

Release APKs split by CPU architecture:

```bash
flutter build apk --release --split-per-abi
```

Expected release paths:

```text
build/app/outputs/bundle/release/app-release.aab
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
build/app/outputs/flutter-apk/app-x86_64-release.apk
```

---

# 5. Repository bootstrap commands — copy/paste version

From a fresh clone:

```bash
git clone https://github.com/rahulrtk74747474-glitch/Data_career.git
cd Data_career

flutter create \
  --platforms=android \
  --project-name dataquest_analyst_career \
  --org com.dataquest \
  .

dart run tool/configure_android_notifications.dart
flutter pub get
flutter analyze
flutter test
flutter run
```

CI-equivalent build:

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build apk --release --split-per-abi
dart run tool/check_release_budgets.dart
```

---

# 6. Current pubspec dependencies

Current production dependencies:

| Package | Purpose |
|---|---|
| `flutter` | Flutter UI/runtime |
| `flutter_riverpod` | dependency injection and reactive state |
| `sqflite` | on-device SQLite database |
| `shared_preferences` | lightweight local settings/progress metadata |
| `path` | safe cross-platform local paths |
| `fl_chart` | skill radar and analytics charts |
| `flutter_local_notifications` | local Daily Challenge/Review reminders |
| `flutter_timezone` | local timezone resolution for reminders |
| `timezone` | timezone-aware notification scheduling |
| `file_picker` | portable backup import |
| `share_plus` | Android share sheet for backups/portfolio/certificate |
| `cross_file` | shareable local file abstraction |
| `open_file` | open generated local HTML artifacts |
| `http` | optional weekly content/cloud REST requests |
| `pdf` | lightweight local PDF/document support where used by v1.1 |
 
Development/test dependencies:

| Package | Purpose |
|---|---|
| `flutter_test` | Flutter unit/widget testing |
| `flutter_lints` | static-analysis rules |
| `sqflite_common_ffi` | SQLite tests on CI/Linux |

Current `pubspec.yaml` is the source of truth for exact versions.

---

# 7. Clean architecture used by DataQuest

DataQuest uses a pragmatic feature-first clean architecture.

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── navigation/
│   │   └── app_routes.dart
│   └── theme/
│       └── app_theme.dart
├── data/
│   └── app_database.dart
├── models/
│   ├── analyst_task.dart
│   ├── skill_mastery.dart
│   ├── boss_case.dart
│   ├── interview.dart
│   ├── capstone.dart
│   ├── backup_snapshot.dart
│   └── ...
├── repositories/
│   ├── content_repository.dart
│   ├── mastery_repository.dart
│   ├── evidence_repository.dart
│   ├── portfolio_repository.dart
│   └── ...
├── services/
│   ├── sql_runner.dart
│   ├── sql_result_grader.dart
│   ├── scoring_service.dart
│   ├── job_readiness_service.dart
│   ├── backup_service.dart
│   ├── cloud_sync_service.dart
│   └── ...
└── features/
    ├── splash/
    ├── home/
    ├── task/
    ├── practice/
    ├── review/
    ├── sql_workspace/
    ├── spreadsheet/
    ├── pandas/
    ├── analytics/
    ├── insight/
    ├── dashboard/
    ├── events/
    ├── achievements/
    ├── interview/
    ├── boss_case/
    ├── portfolio/
    ├── graduation/
    ├── reminders/
    └── continuity/

assets/
└── content/
    └── versioned JSON content packs

test/
└── unit, database, content and widget tests

tool/
├── configure_android_notifications.dart
└── check_release_budgets.dart

docs/
├── GAME_DESIGN_DOCUMENT_v1_1.md
├── FLUTTER_SETUP_AND_ARCHITECTURE_v1_1.md
└── supabase_phase10.sql
```

## Layer responsibilities

### `features/`
Screens and feature-specific presentation logic.

A feature may:
- watch Riverpod providers;
- collect user input;
- call repositories/services;
- render state/results.

It should not directly own database migration logic.

### `models/`
Immutable or mostly immutable domain/content models.

Examples:
- task definitions;
- mastery records;
- interview definitions;
- evidence attempts;
- backup snapshots.

### `repositories/`
Persistence and content access.

Examples:
- SQLite reads/writes;
- loading JSON content;
- storing task/interview results.

### `services/`
Pure or focused business logic.

Examples:
- grading;
- readiness calculation;
- SQL execution;
- backup validation/merge;
- notification scheduling.

### `data/`
Database creation, versioning, schema and migrations.

### `core/`
App-wide primitives:
- navigation;
- theming.

---

# 8. State management

DataQuest uses Riverpod.

High-level provider categories:
- database/provider singletons;
- repositories;
- content futures;
- game progress;
- mastery;
- career recommendations;
- interview/portfolio/readiness state;
- optional cloud/weekly content;
- reminder settings.

General rule:

**UI → provider → repository/service → SQLite/assets**

The UI should not manually open SQLite connections.

---

# 9. Theme

DataQuest uses Material 3.

## Light theme

Seed color:
- `#3157D5`

Background:
- `#F7F8FC`

The light theme uses:
- `ColorScheme.fromSeed`;
- Material 3;
- outlined text inputs;
- non-centered app-bar titles.

## Dark theme

Seed color:
- `#8EA6FF`

Brightness:
- `Brightness.dark`

The app follows the device theme:

```dart
themeMode: ThemeMode.system
```

Theme implementation:

`lib/core/theme/app_theme.dart`

---

# 10. Navigation architecture

Navigation constants and screen mapping live in:

`lib/core/navigation/app_routes.dart`

Important routes include:

```text
/                  Splash
/home              Home/Career Dashboard
/practice          Practice Gym
/review            Review Queue
/sql               SQL Workstation
/spreadsheet       Spreadsheet Lab
/pandas             Pandas Lab
/analytics          Analytics Studio
/insight            Insight Coach
/events             Random Events
/monthly-review     Monthly Performance Review
/daily              Daily Challenge
/weekly             Weekly Analyst Case
/interview          Interview Mode
/boss               Weekly Boss Case
/portfolio          Portfolio
/achievements       Badges
/readiness          Job Readiness
/continuity         Backup / Cloud / Diagnostics
```

The root `MaterialApp` uses:

```dart
initialRoute: AppRoutes.splash
onGenerateRoute: AppRoutes.onGenerateRoute
```

Feature screens may still use `MaterialPageRoute` for short-lived drill-down screens that require typed constructor parameters.

This hybrid approach keeps:
- top-level destinations stable and deep-linkable;
- task/detail navigation type-safe.

---

# 11. Splash/startup lifecycle

Implementation:

`lib/features/splash/splash_screen.dart`

Startup sequence:

```text
main()
  ↓
ProviderScope
  ↓
DataQuestApp
  ↓
SplashScreen
  ↓
Open/migrate local SQLite
  ↓
Install/update bundled versioned content packs
  ↓
Resolve pending notification launch payload
  ↓
HomeScreen
  ↓
Optional notification target (Daily/Review)
```

The splash screen deliberately performs real startup work instead of being a fixed timer.

It shows:
- DataQuest identity;
- current startup step;
- offline-first message;
- retry action if local initialization fails.

The app does **not** block startup on:
- cloud login;
- internet;
- weekly remote feed;
- notifications.

These are optional.

---

# 12. Notification launch navigation

A notification tap is mapped by:

`NotificationDestinationService`

Supported destinations:
- Daily Challenge;
- Review Queue.

If Android launches a stopped app from a notification:

1. `DataQuestApp` records the pending payload;
2. Splash completes local initialization;
3. Splash replaces itself with Home;
4. the notification target is pushed after Home.

This prevents the notification route from racing the database/content startup.

---

# 13. Home screen responsibilities

Home is the career hub, not the business-logic layer.

It displays:
- company/role progress;
- placement/adaptive-learning status;
- online/offline configuration chip;
- feature grid;
- recommendations;
- company metrics;
- current career tickets.

It links to specialized feature screens rather than implementing their logic itself.

---

# 14. Offline-first startup rules

The app must start successfully when:
- airplane mode is enabled;
- Supabase is not configured;
- the weekly content endpoint is absent;
- notification permission is denied.

Startup-critical dependencies are only:
- bundled Flutter assets;
- local SQLite;
- local preferences.

Remote systems must never be required to reach Home.

---

# 15. Exact development commands

Format:

```bash
dart format lib test tool
```

Analyze:

```bash
flutter analyze
```

Run all tests:

```bash
flutter test
```

Run one test:

```bash
flutter test test/widget_test.dart
```

Run app:

```bash
flutter run
```

Build debug APK:

```bash
flutter build apk --debug
```

Build release AAB:

```bash
flutter build appbundle --release
```

Build architecture-specific release APKs:

```bash
flutter build apk --release --split-per-abi
```

Check release budgets after builds:

```bash
dart run tool/check_release_budgets.dart
```

---

# 16. Optional online build configuration

The app is offline-first. Do not add these unless optional cloud features are desired.

```bash
flutter run \
  --dart-define=DATAQUEST_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=DATAQUEST_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY \
  --dart-define=DATAQUEST_WEEKLY_CASE_URL=https://example.com/weekly.json
```

Never commit:
- passwords;
- user access tokens;
- service-role keys;
- signing passwords.

---

# 17. CI equivalence

The GitHub Actions workflow performs the same important steps:

1. checkout;
2. Flutter stable setup;
3. Android wrapper generation;
4. Android DataQuest configuration;
5. SQLite test library install;
6. `flutter pub get`;
7. `flutter analyze`;
8. `flutter test`;
9. debug APK;
10. release AAB;
11. per-ABI release APKs;
12. size-budget check;
13. artifact upload.

Therefore a green main-branch run means the documented bootstrap process is exercised continuously.

---

# 18. Item 2 definition of done

Expansion Item 2 is complete when:

- Android Studio setup is documented;
- Codespaces setup is documented;
- exact bootstrap commands are documented;
- all packages are documented by purpose;
- folder architecture is documented;
- light/dark theme is verified;
- named top-level navigation is in place;
- startup uses a real splash screen;
- splash initializes SQLite/content before Home;
- notification cold-start routing waits until startup is safe;
- startup has retry/error UI;
- analyzer/tests/build remain green.

Item 3 must not begin until the user explicitly confirms moving forward.
