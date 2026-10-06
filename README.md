# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work through realistic company tickets, datasets, interviews, performance reviews and career progression.

## Current build: Phase 6

Phase 6 extends the career and evidence system into banking analytics:

- Lead Analyst unlocks **NorthStar Bank Analytics**
- Synthetic banking datasets for accounts, loans and transaction-review workload
- Advanced credit-risk, fraud-operations, SQL and credit-governance tickets
- Company-aware Boss Cases for e-commerce, SaaS and banking
- Expanded Daily Challenge rotation through the banking stage
- Advanced Bank Analytics Interview round
- Immutable append-only attempt history for tickets, labs, interviews and Boss Cases
- Strongest-score summary tables remain available alongside full history
- Local HTML portfolio report with print styling for browser **Print → Save as PDF**
- SQLite v5 migration preserving earlier career, mastery, interview, Boss Case and portfolio data
- 47-test verified regression suite

Earlier systems remain available: Practice Gym, adaptive review, real SQLite workstation, Python/Pandas Lab, Dashboard Decision Lab, Interview Mode, Daily Challenge and Performance Reviews.

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

The core career game, company progression, banking datasets, interviews, Daily Challenges, SQLite SQL execution, guided Pandas simulator, mastery, Boss Cases, evidence history and portfolio export work entirely on-device.

Banking content uses synthetic training data only. Transaction `review_flag` values represent items requiring review, not confirmed fraud.

The portfolio HTML file is generated locally. Open it in a browser and use **Print → Save as PDF** when a PDF copy is needed.
