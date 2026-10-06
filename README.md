# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work by simulating company tickets, datasets, analysis, decisions and career progression.

## Current build: Phase 3

Phase 3 adds the first adaptive practice loop and end-to-end analyst case:

- Practice Gym organized by skill and difficulty
- Adaptive review queue driven by mastery and spaced-review due dates
- Home-screen task recommendations from weakest unfinished skills
- SQL schema/table browser
- Reusable read-only SQL scratchpad
- Real SQLite JOIN and filtering/aggregation tickets
- Versioned SQLite migration that preserves Phase 2 data
- Weekly Boss Case: cleaning → SQL → KPI → chart choice → executive recommendation
- Weighted Boss Case rubric and persistent performance record
- Boss Case performance feeds back into skill mastery
- Full offline operation
- Automated tests for review prioritization, recommendations, SQL workspace, Boss Case scoring and saved results

Read `PROGRESS_LOG.md` before making future changes.

## Run locally

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

GitHub Actions also analyzes, tests and builds a debug APK on every push to `main`.

## Offline analyst database

Learning tables:
- `campaign_performance`
- `customer_dirty`
- `customers`
- `orders`

Adaptive state:
- `skill_mastery`
- `placement_results`
- `boss_case_results`

The SQL workstation is read-only for learners; mutation statements remain blocked.
