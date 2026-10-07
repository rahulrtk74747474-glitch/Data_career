# DataQuest v1.1 — Flutter Setup, Architecture and Startup Guide

Status: **Expansion Item 2**
Project: **DataQuest: Analyst Career**
Repository: `https://github.com/rahulrtk74747474-glitch/Data_career.git`
Flutter package: `dataquest_analyst_career`
Current app version: **1.1.0+11**

---

# 1. What this guide covers

This guide takes a new contributor from a blank machine or GitHub Codespace to a running DataQuest Android build.

It also documents:
- required tools;
- exact bootstrap commands;
- Android Studio setup;
- GitHub Codespaces setup;
- why the Android wrapper is generated;
- package dependencies;
- clean project structure;
- Material light/dark theming;
- startup/splash flow;
- named-route navigation;
- testing;
- APK/AAB builds;
- optional cloud configuration.

DataQuest remains **offline-first**. Cloud features are optional and are never required to run Career Mode, labs, interviews, capstones, portfolio or graduation.

---

# 2. Toolchain requirements

Use:

- Flutter **stable** channel
- Dart version compatible with `>=3.12.0 <4.0.0`
- Android Studio current stable
- Android SDK + platform tools
- JDK 17
- Git
- an Android device with USB debugging or an Android emulator

Useful checks:

```bash
flutter --version
dart --version
java -version
git --version
flutter doctor -v
```

Do not continue until `flutter doctor -v` shows a usable Flutter install and Android toolchain.

---

# 3. Clone the project

```bash
git clone https://github.com/rahulrtk74747474-glitch/Data_career.git
cd Data_career
```

Verify the branch:

```bash
git status
git branch --show-current
```

Expected branch for normal development:

```text
main
```

---

# 4. Why the Android folder is generated

The repository intentionally keeps the Flutter application source portable and generates the Android platform wrapper when required.

If `android/` is missing, create it with:

```bash
flutter create \
  --platforms=android \
  --project-name dataquest_analyst_career \
  --org com.dataquest \
  .
```

Then apply DataQuest's Android configuration:

```bash
dart run tool/configure_android_notifications.dart
```

That script configures the generated Android project for:
- Java 17;
- local scheduled notifications;
- reboot rescheduling receivers;
- Android Internet permission for optional online features;
- core library desugaring;
- multidex support.

Run the script again whenever the Android wrapper is regenerated.

---

# 5. Android Studio setup from a blank machine

## 5.1 Install Android Studio

Install Android Studio from the official Android developer site.

During first-run setup install:
- Android SDK;
- Android SDK Platform;
- Android SDK Platform-Tools;
- Android SDK Build-Tools;
- Android Emulator;
- Android SDK Command-line Tools.

In Android Studio:

```text
Settings / Preferences
→ Languages & Frameworks
→ Android SDK
```

Ensure at least one current Android platform and the current build tools are installed.

## 5.2 Install Flutter

Install Flutter stable and add `flutter/bin` to your PATH.

Then run:

```bash
flutter channel stable
flutter upgrade
flutter doctor -v
```

Accept Android licenses:

```bash
flutter doctor --android-licenses
```

## 5.3 Open DataQuest

In Android Studio:

```text
File → Open → Data_career
```

Open the integrated terminal and run:

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

## 5.4 Run on a real Android phone

Enable:
- Developer options;
- USB debugging.

Connect the phone and check:

```bash
flutter devices
```

Then run:

```bash
flutter run
```

Choose a device explicitly when multiple devices are attached:

```bash
flutter run -d DEVICE_ID
```

## 5.5 Run in an emulator

Create an Android Virtual Device from:

```text
Tools → Device Manager
```

Start the emulator, then:

```bash
flutter devices
flutter run
```

---

# 6. GitHub Codespaces setup

The simplest Codespaces workflow is to use a Linux Codespace and install Flutter stable in the workspace environment.

## 6.1 Create the Codespace

From the repository:

```text
Code → Codespaces → Create codespace on main
```

## 6.2 Install system dependencies

In the Codespaces terminal:

```bash
sudo apt-get update
sudo apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  libsqlite3-dev \
  openjdk-17-jdk
```

Verify Java:

```bash
java -version
```

## 6.3 Install Flutter stable

```bash
git clone https://github.com/flutter/flutter.git \
  --branch stable \
  --depth 1 \
  "$HOME/flutter"

echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bashrc"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter doctor -v
```

## 6.4 Android SDK in Codespaces

A plain Codespace may not include the Android SDK. If it is not present, install the Android command-line tools and set:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

Persist those values:

```bash
cat >> "$HOME/.bashrc" <<'EOF'
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$HOME/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
EOF
```

After installing command-line tools, install a platform/build tool set supported by the current Flutter stable toolchain:

```bash
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"
```

Recheck:

```bash
flutter doctor -v
```

If Android tooling is intentionally unavailable in the Codespace, you can still run Dart/Flutter static analysis and most non-device tests after installing Flutter and SQLite development libraries.

## 6.5 Bootstrap DataQuest in Codespaces

From the repository root:

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

Build:

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build apk --release --split-per-abi
```

---

# 7. Exact normal developer command sequence

For a fresh clone:

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

Before committing:

```bash
flutter analyze
flutter test
```

Release verification:

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build apk --release --split-per-abi
dart run tool/check_release_budgets.dart
```

---

# 8. Optional online configuration

No cloud endpoint or secret is required for the app.

Offline run:

```bash
flutter run
```

Optional Supabase continuity:

```bash
flutter run \
  --dart-define=DATAQUEST_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=DATAQUEST_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Optional remote weekly-case feed:

```bash
flutter run \
  --dart-define=DATAQUEST_WEEKLY_CASE_URL=https://example.com/dataquest-weekly.json
```

All online defines can be combined.

Do not commit:
- passwords;
- private service-role keys;
- access tokens;
- signing passwords.

---

# 9. pubspec.yaml package map

Current runtime packages:

| Package | Purpose |
|---|---|
| `flutter` | Flutter application framework |
| `flutter_riverpod` | state management and dependency injection |
| `sqflite` | local SQLite database |
| `shared_preferences` | small local settings/progress values |
| `fl_chart` | skill radar and analytical visualizations |
| `flutter_local_notifications` | local Daily/Review reminders |
| `flutter_timezone` | device timezone lookup for reminder scheduling |
| `timezone` | timezone-aware notification scheduling |
| `path` | database/export filesystem paths |
| `http` | optional Supabase and weekly-content HTTP requests |
| `file_picker` | portable backup JSON import |
| `share_plus` | Android share-sheet delivery |
| `cross_file` | file abstraction used by sharing |
| `open_file` | open locally generated portfolio/certificate files |
| `pdf` | local PDF portfolio/export support |

Development packages:

| Package | Purpose |
|---|---|
| `flutter_test` | widget/unit testing |
| `flutter_lints` | static-analysis rules |
| `sqflite_common_ffi` | SQLite tests on desktop/Linux CI |

Install/update dependencies:

```bash
flutter pub get
flutter pub outdated
```

Do not upgrade packages blindly. Run the full regression suite after dependency changes.

---

# 10. Clean architecture used by DataQuest

DataQuest uses a pragmatic feature-first architecture:

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
├── features/
│   ├── achievements/
│   ├── analytics/
│   ├── boss_case/
│   ├── career/
│   ├── continuity/
│   ├── daily/
│   ├── dashboard/
│   ├── events/
│   ├── game/
│   ├── graduation/
│   ├── home/
│   ├── insight/
│   ├── interview/
│   ├── online/
│   ├── pandas/
│   ├── placement/
│   ├── portfolio/
│   ├── practice/
│   ├── reminders/
│   ├── review/
│   ├── skills/
│   ├── splash/
│   ├── spreadsheet/
│   ├── sql_workspace/
│   └── task/
├── models/
├── repositories/
└── services/
```

Supporting project structure:

```text
assets/
└── content/
    └── versioned JSON learning packs

test/
└── unit, repository, SQLite, widget and release regression tests

tool/
├── configure_android_notifications.dart
└── check_release_budgets.dart

docs/
├── GAME_DESIGN_DOCUMENT_v1_1.md
├── FLUTTER_SETUP_v1_1.md
└── supabase_phase10.sql

.github/
└── workflows/
    └── flutter_ci.yml
```

Responsibilities:

### `features/`

UI and feature-specific interaction state.

Examples:
- `features/sql_workspace` — SQL editor/workstation;
- `features/spreadsheet` — touch-first spreadsheet/cleaning lab;
- `features/interview` — interview rounds/sessions;
- `features/splash` — startup initialization and recovery UI.

### `models/`

Pure data definitions parsed from SQLite or versioned JSON.

### `repositories/`

Persistent data access.

Repositories should not contain visual/UI code.

### `services/`

Business logic, graders, simulators, content installation, sync and exports.

Services should remain independently testable where practical.

### `data/`

Database construction, migrations and seed data.

### `core/`

Cross-feature framework concerns:
- navigation;
- themes;
- future shared accessibility/localization utilities.

---

# 11. State management

Riverpod is the single dependency-injection/state-management layer.

The root is:

```dart
runApp(const ProviderScope(child: DataQuestApp()));
```

Shared providers live primarily in:

```text
lib/features/game/game_providers.dart
```

Guidelines:
- UI watches providers;
- repositories own persistence;
- services own domain logic;
- screens should not construct separate database instances;
- invalidate affected providers after writes;
- keep network services optional.

---

# 12. App theme

Theme entry point:

```text
lib/core/theme/app_theme.dart
```

DataQuest uses:
- Material 3;
- seeded color schemes;
- system light/dark mode;
- light scaffold background optimized for card-heavy dashboards;
- consistent outlined input fields.

App wiring:

```dart
MaterialApp(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
)
```

The app therefore follows the Android system theme automatically.

---

# 13. Startup and splash flow

Entry point:

```text
lib/main.dart
```

Flow:

```text
main()
  ↓
ProviderScope
  ↓
DataQuestApp
  ↓
named initial route "/"
  ↓
SplashScreen
  ↓
open/migrate SQLite
  ↓
install/upgrade bundled versioned content packs
  ↓
resolve pending notification deep-link
  ↓
replace Splash with Home
  ↓
optionally open Daily Challenge or Review Queue
```

Splash source:

```text
lib/features/splash/splash_screen.dart
```

The splash screen displays:
- DataQuest identity;
- startup status;
- offline guarantee;
- progress indicator;
- retry UI if initialization fails.

It does **not** use a fake fixed delay. It stays visible only while required startup work runs.

A content/database startup error is recoverable through the Retry button instead of crashing into a blank screen.

---

# 14. Navigation

Navigation source:

```text
lib/core/navigation/app_routes.dart
```

Important routes:

| Route | Destination |
|---|---|
| `/` | Splash |
| `/home` | Home |
| `/practice` | Practice Gym |
| `/review` | Review Queue |
| `/sql` | SQL Workstation |
| `/spreadsheet` | Spreadsheet Lab |
| `/pandas` | Pandas Lab |
| `/analytics` | Analytics Studio |
| `/insight` | Insight Coach |
| `/events` | Random Events |
| `/monthly-review` | Monthly Review |
| `/daily` | Daily Challenge |
| `/weekly` | Weekly Case |
| `/interview` | Interview Mode |
| `/boss` | Boss Case |
| `/portfolio` | Portfolio |
| `/achievements` | Badges |
| `/readiness` | Job Readiness |
| `/continuity` | Backup/Cloud |

`MaterialApp.onGenerateRoute` is the central route factory.

The Home screen remains the hub, while notification payloads can deep-link into:
- Daily Challenge;
- Review Queue.

Unknown named routes safely fall back to Home.

---

# 15. Home screen

Home source:

```text
lib/features/home/home_screen.dart
```

Home displays:
- company/chapter;
- career role and XP;
- Daily Challenge streak;
- company metrics;
- placement/adaptive-learning status;
- recommended weak-topic work;
- current career tickets;
- feature launcher grid;
- offline/optional-online state indicator.

The feature launcher is touch-first and uses Material cards with icons, titles and short descriptions.

---

# 16. Content assets

All versioned offline content lives under:

```text
assets/content/
```

Examples include:
- career task packs;
- SQL curriculum;
- spreadsheet/cleaning challenges;
- Pandas challenges;
- dashboard/analytics challenges;
- interviews;
- Boss Cases;
- narrative/dialogue content;
- daily/weekly challenges;
- final capstone.

The whole folder is declared in `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/content/
```

Startup installation is handled by the content-pack loader, which is invoked by Splash before Home opens.

---

# 17. Testing commands

Static analysis:

```bash
flutter analyze
```

All tests:

```bash
flutter test
```

Single test:

```bash
flutter test test/widget_test.dart
```

Verbose test:

```bash
flutter test -r expanded
```

Important regression categories include:
- SQLite schema/migrations;
- graders;
- content loading/versioning;
- career progression;
- backup/restore;
- optional cloud merge;
- accessibility;
- low-memory asset budget;
- startup Splash → Home.

---

# 18. GitHub Actions

Workflow:

```text
.github/workflows/flutter_ci.yml
```

Every verified build:
1. checks out source;
2. installs Flutter stable;
3. generates Android wrapper when missing;
4. applies Android configuration;
5. installs SQLite test library;
6. installs Flutter dependencies;
7. runs `flutter analyze`;
8. runs all tests;
9. builds debug APK;
10. builds release AAB;
11. builds split release APKs;
12. checks size budgets;
13. uploads artifacts.

Never mark a development item complete if the relevant integrated CI run is failing.

---

# 19. Release commands

Debug APK:

```bash
flutter build apk --debug
```

Release AAB:

```bash
flutter build appbundle --release
```

Split release APKs:

```bash
flutter build apk --release --split-per-abi
```

Expected direct-install files are under:

```text
build/app/outputs/flutter-apk/
```

AAB:

```text
build/app/outputs/bundle/release/app-release.aab
```

Check budgets:

```bash
dart run tool/check_release_budgets.dart
```

Production Play signing is a separate release-operations concern and should never commit the private keystore or passwords.

---

# 20. Common setup problems

## `flutter: command not found`

Flutter is not in PATH.

Check:

```bash
which flutter
echo "$PATH"
```

## Android SDK not found

Check:

```bash
echo "$ANDROID_HOME"
echo "$ANDROID_SDK_ROOT"
flutter doctor -v
```

## Android licenses

Run:

```bash
flutter doctor --android-licenses
```

## Android folder missing

Run:

```bash
flutter create \
  --platforms=android \
  --project-name dataquest_analyst_career \
  --org com.dataquest \
  .
dart run tool/configure_android_notifications.dart
```

## SQLite tests fail on Linux

Install:

```bash
sudo apt-get install -y libsqlite3-dev
```

## Dependency resolution issue

Run:

```bash
flutter pub get
flutter pub outdated
```

Do not delete working version constraints without reviewing transitive conflicts.

## Blank/failed startup

The app should show a startup error/retry state instead of a white screen.

Run:

```bash
flutter analyze
flutter test test/widget_test.dart
```

Then inspect:
- SQLite migration;
- bundled content-pack parsing;
- missing asset declarations.

---

# 21. Expansion Item 2 acceptance checklist

Item 2 is complete when:

- [x] Flutter project is already runnable from source.
- [x] Material 3 light/dark theme is wired.
- [x] Splash screen is the initial route.
- [x] Splash opens/migrates SQLite.
- [x] Splash installs versioned bundled content.
- [x] Splash has retry behavior.
- [x] Home opens only after required startup work completes.
- [x] Named navigation routes are centralized.
- [x] notification launch routing remains supported.
- [x] Android Studio setup is documented.
- [x] Codespaces setup is documented.
- [x] exact clone/bootstrap/run/test/build commands are documented.
- [x] package purposes are documented.
- [x] folder architecture is documented.
- [x] Android wrapper generation is documented.
- [x] optional cloud defines are documented.
- [x] release commands are documented.

This item does not alter Item 3's SQLite/content-pack architecture work beyond documenting the current startup loader.
