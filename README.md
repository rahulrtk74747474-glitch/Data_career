# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work through realistic company tickets, datasets, interviews, performance reviews, company chapters and career progression.

## Current build: Phase 8

Phase 8 completes the current five-company journey while keeping the career role ladder independent.

Current company path:
- E-commerce Co.
- SaaS Growth Co.
- NorthStar Bank Analytics
- Harborview Hospital Analytics
- **Logistics Network Co.**
- final company-journey completion review

New Phase 8 capabilities:
- Hospital → Logistics unlock through the existing evidence-gated Company Chapter Review
- persisted final five-company journey completion without adding a role above Head of Analytics
- SQLite v7 synthetic logistics datasets for shipments, route SLA, warehouse inventory flow, throughput forecasts and operating cost
- ten Advanced Logistics Analytics tickets spanning SQL, cleaning, statistics, SLA, warehouse capacity, normalized cost, route cohorts, delay-driver analysis, forecasting and executive communication
- Logistics-specific Boss Case
- Logistics Daily Challenges
- chapter-gated Logistics Analytics Interview
- Logistics tables in the SQL Workstation
- notification taps now deep-link into Daily Challenge or Review Queue, including notification-launched app starts
- portfolio reports can be generated, opened with a device app, or shared through Android's native share sheet
- lightweight HTML + browser Print → Save as PDF remains the PDF path to avoid bundling a heavy PDF renderer
- 77-test verified regression suite

Earlier systems remain available: Practice Gym, adaptive review, Python/Pandas Lab, Dashboard Decision Lab, Interview Mode, Daily Challenge, Performance Reviews, company-aware Boss Cases, local reminders, immutable evidence history and portfolio export.

Read `PROGRESS_LOG.md` before making future changes.

## Run locally

The Android wrapper is generated on demand in this repository. After generating it, apply the checked-in notification configuration script:

```bash
flutter create --platforms=android --project-name dataquest_analyst_career --org com.dataquest .
dart run tool/configure_android_notifications.dart
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

GitHub Actions automatically generates/configures the Android wrapper, analyzes the project, runs tests, builds a debug APK, and uploads it as an artifact.

## Offline design

The career game, all five company chapters, synthetic datasets, SQL execution, guided Pandas simulator, mastery, Boss Cases, interviews, company-journey state, evidence history, reminder preferences and portfolio generation work locally.

Learning reminders use local Android notifications. Tapping a DataQuest Daily Challenge reminder opens Daily Challenge; tapping a Review Queue reminder opens Review Queue.

The portfolio report is generated locally as HTML. It can be opened or shared from the app, and a browser can use **Print → Save as PDF** without shipping a heavyweight PDF engine.
