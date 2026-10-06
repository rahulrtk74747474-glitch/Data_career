# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work by simulating company tickets, datasets, analysis, decisions and career progression.

## Current build: Phase 4

Phase 4 adds the first Python/Pandas, dashboard-design and portfolio-evidence systems:

- Guided offline Python/Pandas dataframe simulator
- Six Pandas challenges across Beginner, Intermediate and Advanced
- Filtering, fillna, groupby/sum, sorting/head, derived ratios and filter+aggregate workflows
- Dedicated Python/Pandas mastery skill
- Dashboard Decision Lab for KPI design, chart choice, hierarchy and visual critique
- Persistent strongest-score/attempt evidence for tickets and labs
- Portfolio Evidence screen combining strongest work and Boss Case results
- Offline copy-to-clipboard portfolio summary
- Expanded Practice Gym task bank and skill filter
- SQLite v3 migration that preserves earlier progress
- Automated Pandas and portfolio tests

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

GitHub Actions also analyzes, tests and builds a debug APK on pushes to `main`.

## Offline design

No Python runtime is bundled. The Pandas Lab validates realistic Pandas operation patterns and executes equivalent dataframe operations in Dart against small synthetic datasets. This keeps the app lightweight and fully offline while teaching common analyst workflows.
