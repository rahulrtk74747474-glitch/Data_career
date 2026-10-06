# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a student for real data-analyst work through realistic company tickets, datasets, interviews, performance reviews, company chapters and career progression.

## Current build: Phase 7

Phase 7 separates the **career role ladder** from the **company chapter path**, so a player can stay Head of Analytics while continuing into new industries.

Current company path:
- E-commerce Co.
- SaaS Growth Co.
- NorthStar Bank Analytics
- **Harborview Hospital Analytics**
- Logistics Network Co. is reserved for the next phase.

New Phase 7 capabilities:
- persistent company chapter state independent of role
- evidence-gated Company Chapter Review
- bank → hospital unlock without inventing a role above Head of Analytics
- SQLite v6 synthetic hospital operations datasets
- hospital SQL, cleaning, statistics, capacity-planning, forecasting, cohort and executive-communication tickets
- hospital-specific Boss Case
- hospital Daily Challenges
- hospital-specific Interview round
- bank + hospital learning tables in the SQL Workstation
- user-controlled local reminders for Daily Challenge and Review Queue
- local notification permission requested only when a reminder is enabled
- inexact daily reminder scheduling to avoid exact-alarm permission
- backward migration of existing saves to the company chapter they had already reached
- 62-test verified regression suite

All hospital content uses aggregate synthetic operations data only. DataQuest does **not** include real PHI, patient identities, diagnoses, treatment recommendations, or clinical decision support.

Earlier systems remain available: Practice Gym, adaptive review, Python/Pandas Lab, Dashboard Decision Lab, Interview Mode, Daily Challenge, Performance Reviews, company-aware Boss Cases, immutable evidence history, and local HTML/PDF-ready portfolio export.

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

The core career game, company chapters, hospital and banking datasets, SQL execution, guided Pandas simulator, mastery, Boss Cases, interviews, evidence history, portfolio export, and reminder preferences work locally.

Learning reminders use local Android notifications. The player separately controls Daily Challenge and Review Queue reminders and can choose their times. Scheduling is inexact, so Android may deliver a reminder near rather than exactly at the requested minute.

The portfolio HTML file is generated locally. Open it in a browser and use **Print → Save as PDF** when a PDF copy is needed.
