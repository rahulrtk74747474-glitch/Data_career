# DataQuest: Analyst Career

A Flutter learning game that simulates a real data-analyst career. Players solve company tickets with spreadsheets, SQL, statistics, Python/Pandas concepts, dashboards, business analytics, and communication.

## Current phase

Phase 1 is a playable vertical slice:
- Career dashboard with company metrics, role and XP
- JSON-driven task content
- Spreadsheet, SQL, and communication starter tickets
- 3-level hint system
- Auto-grading with explanations and retry
- Offline progress saved on-device
- GitHub Actions analysis, tests, and Android debug APK build

Read `PROGRESS_LOG.md` before making future changes.

## Run locally

1. Install Flutter stable and Android Studio.
2. Clone this repository.
3. From the repository root run:
   ```bash
   flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
   flutter pub get
   flutter run
   ```

The first `flutter create` command generates the standard Android platform wrapper. App source and game content are already in this repository.

## Build an APK

```bash
flutter build apk --release
```

Output:
`build/app/outputs/flutter-apk/app-release.apk`

GitHub Actions also builds a debug APK automatically on every push to `main`.

## Architecture

- `lib/core`: theme and shared app infrastructure
- `lib/features`: game screens and feature state
- `lib/models`: data-driven content models
- `lib/repositories`: local content loading
- `lib/services`: grading/business logic
- `assets/content`: versioned task packs
- `test`: automated tests

## Product direction

The long-term career ladder is Intern → Junior → Analyst → Senior → Lead → Head of Analytics, with later companies covering e-commerce, SaaS, banking, hospitals, and logistics.
