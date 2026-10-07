# DataQuest v1.1 — Flutter Setup, Architecture, Theme and Navigation

Status: **Expansion Item 2**
Repository: `rahulrtk74747474-glitch/Data_career`
Application package: `com.dataquest.dataquest_analyst_career`
Flutter project name: `dataquest_analyst_career`
Current app version: `1.1.0+11`

This document explains how to create/run DataQuest from a clean development machine, how the checked-in Flutter project is organized, why every package exists, and how startup/navigation work.

---

# 1. Important repository design choice

The repository intentionally keeps the Flutter application source, assets, tests and Android configuration script under version control, but the Android platform wrapper can be regenerated.

If `android/` is missing after cloning, generate it with:

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
```

Then apply the project-specific Android configuration:

```bash
dart run tool/configure_android_notifications.dart
```

That script configures the generated Android project for:
- Java 17;
- core-library desugaring;
- multidex;
- local notification receivers;
- reboot notification rescheduling;
- Internet permission for optional online features.

Do not skip this step before a real Android build.

---

# 2. Prerequisites

## Required

- Git
- Flutter **stable**
- Dart version compatible with `>=3.12.0 <4.0.0`
- Android SDK
- JDK 17
- Android Studio or a Linux development environment such as GitHub Codespaces
- an Android device or emulator for interactive testing

## Verify the environment

Run:

```bash
flutter --version
dart --version
java -version
flutter doctor -v
```

Expected:
- Flutter reports the stable channel.
- Dart satisfies the range in `pubspec.yaml`.
- Java reports version 17.
- `flutter doctor -v` can see an Android toolchain.

If Flutter asks you to accept Android licenses:

```bash
flutter doctor --android-licenses
```

Then run:

```bash
flutter doctor -v
```

again.

---

# 3. Setup with Android Studio

## 3.1 Install Android Studio

Install Android Studio from the official Android developer site.

During installation include:
- Android SDK;
- Android SDK Platform Tools;
- Android SDK Build Tools;
- Android Emulator if you want an emulator.

Open **SDK Manager** and make sure the current SDK platform recommended by your installed Flutter stable release is installed.

DataQuest's generated Android build is configured for JDK 17.

## 3.2 Install Flutter and Dart plugins

In Android Studio:

1. Open **Settings / Preferences**.
2. Open **Plugins**.
3. Install the **Flutter** plugin.
4. Allow Android Studio to install/enable the Dart plugin when requested.
5. Restart Android Studio.

## 3.3 Install Flutter SDK

Install the current Flutter stable SDK and add its `bin` directory to PATH.

Verify in a terminal:

```bash
flutter --version
flutter doctor -v
```

## 3.4 Clone DataQuest

From a terminal:

```bash
git clone https://github.com/rahulrtk74747474-glitch/Data_career.git
cd Data_career
```

Open the **repository root** in Android Studio.

## 3.5 Generate the Android wrapper

If the repository does not contain `android/`:

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
```

Apply DataQuest Android configuration:

```bash
dart run tool/configure_android_notifications.dart
```

## 3.6 Install packages

```bash
flutter pub get
```

## 3.7 Verify source before running

```bash
flutter analyze
flutter test
```

## 3.8 Run on a physical Android phone

Enable **Developer options** and **USB debugging** on the phone.

Connect the device, then run:

```bash
flutter devices
flutter run
```

If several devices are present:

```bash
flutter run -d DEVICE_ID
```

## 3.9 Run on an Android emulator

Create an emulator in Android Studio's Device Manager, boot it, then run:

```bash
flutter devices
flutter run
```

---

# 4. Setup with GitHub Codespaces

Codespaces is useful for coding, analysis, tests and Android artifact builds. Interactive Android UI testing is still easier on a local Android device/emulator.

## 4.1 Open a Codespace

From the repository page:

**Code → Codespaces → Create codespace on main**

Open the Codespaces terminal.

## 4.2 Install Flutter stable when the image does not already contain it

Check:

```bash
flutter --version
```

If Flutter is missing:

```bash
cd $HOME
git clone https://github.com/flutter/flutter.git --branch stable --depth 1
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
```

Return to the repository:

```bash
cd /workspaces/Data_career
```

If the Codespace folder name differs:

```bash
pwd
ls
```

and `cd` to the repository root.

## 4.3 Install Linux SQLite test support

DataQuest desktop-side tests use `sqflite_common_ffi`.

Run:

```bash
sudo apt-get update
sudo apt-get install -y libsqlite3-dev
```

## 4.4 Generate/configure Android

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
dart run tool/configure_android_notifications.dart
```

## 4.5 Install and verify

```bash
flutter pub get
flutter analyze
flutter test
```

## 4.6 Build Android artifacts

Debug APK:

```bash
flutter build apk --debug
```

Release app bundle:

```bash
flutter build appbundle --release
```

Release APKs split by CPU architecture:

```bash
flutter build apk --release --split-per-abi
```

Release-size budget check after the builds:

```bash
dart run tool/check_release_budgets.dart
```

---

# 5. Fastest clean bootstrap

For a fresh clone on Linux/Codespaces:

```bash
git clone https://github.com/rahulrtk74747474-glitch/Data_career.git
cd Data_career

flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
dart run tool/configure_android_notifications.dart

sudo apt-get update
sudo apt-get install -y libsqlite3-dev

flutter pub get
flutter analyze
flutter test
flutter run
```

On Windows/macOS, omit the `apt-get` commands.

---

# 6. Current pubspec.yaml

The live project is the source of truth. Current package groups are:

## Runtime packages

### `flutter`
Flutter UI/runtime.

### `flutter_riverpod`
Application state management and dependency injection.

Used for:
- game progress;
- repositories/services;
- content loading;
- mastery/review queues;
- interview and portfolio state;
- readiness/graduation;
- reminders;
- backup/cloud systems.

### `sqflite`
On-device SQLite database.

Used for:
- synthetic company databases;
- SQL Lab execution;
- mastery;
- attempt/result persistence;
- evidence;
- versioned content catalog;
- capstone and interview state.

### `shared_preferences`
Small key/value device state.

Used for:
- game progress JSON;
- reminder settings;
- weekly-case cache metadata;
- backup timestamps and lightweight preferences.

### `path`
Portable filesystem path joining for exports/backups.

### `fl_chart`
Skill radar and analytical charts.

### `flutter_local_notifications`
User-controlled local Daily Challenge and Review Queue reminders.

### `timezone`
Timezone-aware notification schedules.

### `flutter_timezone`
Obtains the device timezone for notification scheduling.

### `http`
Optional network access.

Used for:
- optional Supabase REST cloud continuity;
- optional leaderboard;
- optional remote Weekly Case feed.

The offline core does not depend on successful HTTP access.

### `file_picker`
Select portable JSON backups for restore.

### `share_plus`
Android native share sheet.

Used for:
- portfolio;
- certificate;
- backup files.

### `cross_file`
Cross-platform file representation used by sharing APIs.

### `open_file`
Opens generated portfolio/certificate artifacts using an installed device app.

### `pdf`
Lightweight PDF generation support for portfolio/report delivery features where used.

## Development/test packages

### `flutter_test`
Flutter unit/widget tests.

### `flutter_lints`
Static-analysis rules.

### `sqflite_common_ffi`
SQLite implementation for Dart/Flutter tests on Linux CI and desktop development.

---

# 7. Clean architecture used by DataQuest

DataQuest uses feature-based presentation plus shared domain/data services.

High-level dependency direction:

```text
UI / features
    ↓
Riverpod providers
    ↓
services + repositories
    ↓
models
    ↓
SQLite / SharedPreferences / asset JSON / optional HTTP
```

The UI should not contain raw SQL persistence logic or HTTP implementation details.

---

# 8. Full current Flutter folder map

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
│   ├── achievement_badge.dart
│   ├── analyst_task.dart
│   ├── analytics_challenge.dart
│   ├── backup_snapshot.dart
│   ├── boss_case.dart
│   ├── boss_case_result.dart
│   ├── capstone.dart
│   ├── capstone_result.dart
│   ├── content_pack.dart
│   ├── daily_challenge.dart
│   ├── dashboard_challenge.dart
│   ├── evidence_attempt.dart
│   ├── interview.dart
│   ├── interview_result.dart
│   ├── job_readiness.dart
│   ├── narrative_content.dart
│   ├── pandas_challenge.dart
│   ├── placement_question.dart
│   ├── portfolio_snapshot.dart
│   ├── reminder_settings.dart
│   ├── skill_mastery.dart
│   ├── spreadsheet_challenge.dart
│   ├── sql_table_schema.dart
│   ├── task_performance.dart
│   └── weekly_case.dart
├── repositories/
│   ├── achievement_repository.dart
│   ├── boss_case_result_repository.dart
│   ├── capstone_result_repository.dart
│   ├── content_repository.dart
│   ├── evidence_repository.dart
│   ├── interview_result_repository.dart
│   ├── mastery_repository.dart
│   ├── portfolio_repository.dart
│   ├── reminder_settings_repository.dart
│   ├── sql_workspace_repository.dart
│   └── task_performance_repository.dart
└── services/
    ├── achievement_service.dart
    ├── adaptive_review_service.dart
    ├── analytics_scoring_service.dart
    ├── backup_service.dart
    ├── boss_case_scoring_service.dart
    ├── boss_case_selection_service.dart
    ├── capstone_scoring_service.dart
    ├── career_artifact_service.dart
    ├── career_progression_service.dart
    ├── career_task_service.dart
    ├── certificate_export_service.dart
    ├── cloud_sync_service.dart
    ├── company_chapter_progression_service.dart
    ├── content_pack_loader.dart
    ├── daily_challenge_service.dart
    ├── dashboard_scoring_service.dart
    ├── graduation_service.dart
    ├── insight_scoring_service.dart
    ├── interview_scoring_service.dart
    ├── job_readiness_service.dart
    ├── notification_destination_service.dart
    ├── pandas_simulator.dart
    ├── portfolio_delivery_service.dart
    ├── portfolio_export_service.dart
    ├── portfolio_pdf_export_service.dart
    ├── portfolio_service.dart
    ├── release_diagnostics_service.dart
    ├── reminder_schedule_planner.dart
    ├── reminder_scheduler.dart
    ├── scoring_service.dart
    ├── snapshot_merge_service.dart
    ├── spreadsheet_simulator.dart
    ├── sql_result_grader.dart
    ├── sql_runner.dart
    └── weekly_case_service.dart
```

---

# 9. Folder responsibilities

## `core/`
Application-wide concerns that are not a business feature.

Current responsibilities:
- named navigation;
- Material theme.

## `data/`
Low-level persistent database ownership.

`AppDatabase`:
- opens/migrates SQLite;
- seeds local synthetic company data;
- preserves previous player data through schema upgrades.

## `features/`
Screens and feature-local presentation state.

Rule:
- a feature screen may call a provider/service;
- it should not manually manage database migrations or duplicate grading logic.

## `models/`
Serializable/domain data structures.

Examples:
- tasks;
- interviews;
- Boss Cases;
- content packs;
- mastery;
- readiness;
- reminders.

## `repositories/`
Persistence-facing domain access.

Examples:
- load/save interview summaries;
- load mastery;
- load portfolio;
- record task performance.

## `services/`
Deterministic business logic or external adapters.

Examples:
- SQL grading;
- career progression;
- content-pack installation;
- reminder scheduling;
- backup validation;
- cloud merge;
- portfolio generation.

---

# 10. Offline asset structure

```text
assets/
└── content/
    ├── career task packs
    ├── interview packs
    ├── Boss Case packs
    ├── Pandas challenges
    ├── dashboard challenges
    ├── spreadsheet challenges
    ├── analytics challenges
    ├── narrative/event packs
    ├── weekly fallback case
    └── versioned unified content packs
```

`pubspec.yaml` includes:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/content/
```

New offline content placed under `assets/content/` is bundled into the app when referenced by the corresponding repository/loader.

---

# 11. App theme

DataQuest uses Material 3.

## Light theme

Seed:
`#3157D5`

Background:
`#F7F8FC`

Characteristics:
- high-contrast Material color scheme;
- outlined inputs;
- standard Material accessibility/tap targets;
- system typography.

## Dark theme

Seed:
`#8EA6FF`

Uses:
```dart
ColorScheme.fromSeed(
  seedColor: const Color(0xFF8EA6FF),
  brightness: Brightness.dark,
)
```

## Theme selection

```dart
themeMode: ThemeMode.system
```

The app follows the Android device light/dark setting automatically.

---

# 12. Startup and splash flow

DataQuest now has an explicit startup route rather than opening Home before offline state is ready.

Entry:

```text
main()
  ↓
ProviderScope
  ↓
DataQuestApp
  ↓
AppRoutes.splash
  ↓
SplashScreen
```

The splash performs:

1. open/migrate SQLite;
2. install/update bundled versioned content packs;
3. preserve existing packs when the installed content version is already current;
4. resolve any notification-launch payload;
5. replace Splash with Home;
6. optionally deep-link to Daily Challenge or Review Queue after Home initializes.

Normal navigation:

```text
Splash
  ↓ pushReplacement
Home
```

Notification launch:

```text
Splash
  ↓
Home
  ↓
Daily Challenge OR Review Queue
```

If startup fails, Splash does **not** silently discard progress. It displays the failure and a **Retry startup** action.

Displayed startup states include:
- Opening offline workspace…
- Installing content packs…
- startup retry on failure.

The splash explicitly tells the player that the core learning system works offline.

---

# 13. Navigation

Navigation is centralized in:

`lib/core/navigation/app_routes.dart`

Current named routes:

```text
/                  splash
/home              home
/practice          Practice Gym
/review            Review Queue
/sql               SQL Workstation
/spreadsheet       Spreadsheet Lab
/pandas            Pandas Lab
/analytics         Analytics Studio
/insight           Insight Coach
/events            Random Events
/monthly-review    Monthly Performance Review
/daily             Daily Challenge
/weekly            Weekly Analyst Case
/interview         Interview Mode
/boss              Boss Case
/portfolio         Portfolio
/achievements      Achievements
/readiness         Job Readiness
/continuity        Data & Cloud
```

The route table creates screens in one place and prevents feature screens from depending on one another's concrete navigation implementation.

---

# 14. Home screen responsibility

Home is the career hub, not a data-processing layer.

It should:
- show company/role progress;
- show next recommended work;
- surface feature entry points;
- show career/company status;
- allow safe refresh/reset entry points.

It should not:
- execute raw SQL itself;
- install content packs;
- implement mastery algorithms;
- perform cloud merge logic.

Those concerns remain in services/providers.

---

# 15. Riverpod dependency structure

Central wiring lives in:

`lib/features/game/game_providers.dart`

Examples:

```text
appDatabaseProvider
    ↓
repositories
    ↓
services
    ↓
FutureProviders / StateNotifierProviders
    ↓
feature screens
```

Advantages:
- tests can override the database with in-memory SQLite;
- cloud adapters can be swapped;
- deterministic services remain unit-testable;
- UI screens remain thin.

---

# 16. SQLite testing pattern

Tests use:

`sqflite_common_ffi`

Typical setup:

```dart
sqfliteFfiInit();

final database = AppDatabase(
  factory: databaseFactoryFfi,
  overridePath: inMemoryDatabasePath,
);
```

This gives tests isolated in-memory SQLite without touching real player data.

Linux/Codespaces requires:

```bash
sudo apt-get install -y libsqlite3-dev
```

---

# 17. Content-pack startup behavior

`ContentPackLoader` installs versioned packs from assets into the content catalog.

On Splash:

```dart
await ref.read(contentPackLoaderProvider).installBundledPacks();
```

The loader:
- parses the JSON;
- validates the content schema;
- checks installed `pack_id` + `content_version`;
- skips the pack when the same/newer version is already installed;
- replaces only the rows belonging to that pack for a newer version;
- installs task/dataset/dialogue/rubric/event/achievement catalog rows inside one SQLite transaction.

This keeps startup idempotent.

---

# 18. Exact daily development commands

After the one-time Android wrapper setup:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

After changing dependencies:

```bash
flutter pub get
```

After changing the generated Android wrapper requirements:

```bash
dart run tool/configure_android_notifications.dart
```

Before committing a release candidate:

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle --release
flutter build apk --release --split-per-abi
dart run tool/check_release_budgets.dart
```

---

# 19. Optional online configuration

The app remains fully usable without these.

Optional Supabase:

```bash
flutter run \
  --dart-define=DATAQUEST_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=DATAQUEST_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Optional Weekly Case feed:

```bash
flutter run \
  --dart-define=DATAQUEST_WEEKLY_CASE_URL=https://example.com/dataquest-weekly.json
```

All three together:

```bash
flutter run \
  --dart-define=DATAQUEST_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=DATAQUEST_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY \
  --dart-define=DATAQUEST_WEEKLY_CASE_URL=https://example.com/dataquest-weekly.json
```

Do not commit private service-role keys or passwords.

---

# 20. GitHub Actions equivalent

The checked-in CI performs the same reproducible pipeline:

1. checkout;
2. Flutter stable setup;
3. generate Android wrapper when missing;
4. apply DataQuest Android configuration;
5. install Linux SQLite library;
6. `flutter pub get`;
7. `flutter analyze`;
8. `flutter test`;
9. debug APK;
10. release AAB;
11. split release APKs;
12. release-size budget check;
13. artifact upload.

This workflow is the final source of truth for whether a repository change is buildable.

---

# 21. Troubleshooting

## Flutter command not found

Check PATH:

```bash
which flutter
echo $PATH
```

Then add Flutter's `bin` directory to PATH.

## Android toolchain missing

Run:

```bash
flutter doctor -v
```

Install the missing Android SDK/platform/build tools reported by Flutter.

## Android wrapper missing

Run:

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
dart run tool/configure_android_notifications.dart
```

## Notification build errors

Regenerate/configure the Android wrapper:

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
dart run tool/configure_android_notifications.dart
flutter clean
flutter pub get
```

## Linux SQLite test error

```bash
sudo apt-get update
sudo apt-get install -y libsqlite3-dev
flutter test
```

## Dependency resolution problem

```bash
flutter clean
flutter pub get
flutter pub outdated
```

Do not randomly downgrade packages without checking compatibility with the current Flutter stable/Dart SDK.

## Corrupt local startup/content pack

The Splash screen reports the failure and allows retry.

For development-only reset testing use the in-app explicit reset rather than deleting database tables manually, because the reset path also invalidates provider state correctly.

---

# 22. Clean-architecture rules for future expansion

1. New screens belong under `features/<feature>/`.
2. Reusable domain data belongs under `models/`.
3. SQLite/domain persistence belongs under `repositories/`.
4. Grading/business logic belongs under `services/`.
5. Shared application wiring belongs in Riverpod providers.
6. Shared named navigation belongs in `core/navigation/`.
7. Theme tokens belong in `core/theme/`.
8. New curriculum should be data-driven under `assets/content/` when possible.
9. Never silently drop existing player data during a database migration.
10. Never require cloud access for core learning.
11. Keep CPU/memory-heavy runtimes out of the base APK unless there is a compelling measured reason.
12. Every significant feature must have automated tests.

---

# 23. Item 2 definition of done

Expansion Item 2 is complete when:

- Android Studio setup is documented from a clean machine;
- Codespaces setup is documented from a clean workspace;
- exact clone/bootstrap/test/run/build commands are present;
- all current `pubspec.yaml` packages are explained;
- the real checked-in clean architecture is documented;
- light/dark theme behavior is documented;
- centralized navigation is documented;
- splash initializes SQLite + versioned content before Home;
- startup failures expose retry rather than deleting progress;
- notification launches remain routable through Splash;
- startup/navigation tests pass;
- analyzer and full test suite pass.

The next expansion item must not begin until the user confirms.
