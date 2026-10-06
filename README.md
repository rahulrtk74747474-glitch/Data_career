# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work by simulating company tickets, datasets, analysis, decisions and career progression.

## Current build: Phase 2

The app now includes:
- Career dashboard with company metrics, role and XP
- JSON-driven ticket packs with progressive 3-level hints
- Spreadsheet and statistics/business reasoning tickets
- A real local SQLite analyst workstation
- SQL queries executed on-device and graded from their result sets
- A messy data-cleaning case covering nulls, duplicates, formats, categories and outliers
- 5-question placement test
- Persistent per-skill mastery and review scheduling
- Skill radar chart
- Offline saved career progress
- GitHub Actions analysis, unit tests and Android debug APK build

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

## Test

```bash
flutter analyze
flutter test
```

## Build an APK

```bash
flutter build apk --release
```

Output:
`build/app/outputs/flutter-apk/app-release.apk`

GitHub Actions builds a debug APK automatically on pushes to `main`.

## Architecture

- `lib/data`: SQLite database and seeded analyst datasets
- `lib/core`: app theme/infrastructure
- `lib/features`: career, placement, skills and task UI/state
- `lib/models`: task, placement and mastery models
- `lib/repositories`: content and mastery persistence
- `lib/services`: grading and safe SQL execution
- `assets/content`: versioned data-driven content packs
- `test`: grading, SQLite, mastery and widget tests

## Offline data

SQLite seeds:
- `campaign_performance` for real SQL practice
- `customer_dirty` for cleaning practice
- `skill_mastery` and `placement_results` for adaptive learning state

The full core learning loop works without internet.
