# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work through realistic company tickets, datasets, interviews, performance reviews and career progression.

## Current build: Phase 5

Phase 5 adds the career loop around the technical training:

- Interview Mode with SQL, statistics, analytics case and behavioral rounds
- Timed and untimed interview practice
- Real local SQLite grading for SQL interview questions
- Weighted offline rubrics for case and behavioral answers
- Persistent best/latest interview scores and attempt counts
- Data-driven Daily Challenge rotation
- Consecutive-day Daily Challenge streaks and one-time daily bonus XP
- Performance Review promotion gates instead of XP-only promotion
- E-commerce → SaaS company progression at Data Analyst level
- SaaS-specific retention, MRR-proxy, experiment and NRR tickets
- Role/company-aware Career Mode ticket difficulty
- SQLite v4 migration preserving earlier progress
- 35-test verified regression suite

Phase 4 features remain available: Practice Gym, adaptive review, SQL workstation, Boss Case, Python/Pandas Lab, Dashboard Decision Lab and Portfolio Evidence.

Read `PROGRESS_LOG.md` before making future changes.

## Run locally

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

## Build an APK

```bash
flutter build apk --release
```

GitHub Actions analyzes, tests and builds a debug APK on pushes to `main`.

## Offline design

The core career game, interviews, Daily Challenges, SQLite SQL execution, guided Pandas simulator, mastery, performance reviews and portfolio systems work entirely on-device. No cloud account is required.
