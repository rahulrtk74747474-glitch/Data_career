# DataQuest: Analyst Career

DataQuest is an offline-first Flutter game that trains a learner for real data-analyst work through realistic company tickets, datasets, interviews, performance reviews, company chapters, evidence and career progression.

## Current build: Phase 9

Phase 9 adds the **Graduation & Job-Readiness system** after the complete five-company career journey.

Current journey:
- E-commerce Co.
- SaaS Growth Co.
- NorthStar Bank Analytics
- Harborview Hospital Analytics
- Logistics Network Co.
- **Final cross-company capstone**
- **Interview Gauntlet**
- **Job Readiness & Graduation**

New Phase 9 capabilities:
- SQLite v8 final cross-company synthetic KPI dataset
- six-part final analyst capstone: data cleaning, SQL, statistics, KPI, dashboard choice and executive recommendation
- persisted capstone result plus immutable capstone attempt evidence
- transparent Job Readiness Score based on demonstrated evidence rather than XP
- readiness breakdowns for SQL, spreadsheets/cleaning, statistics, Python/Pandas, business communication and interviews
- targeted remediation recommendations for weak domains
- 15-minute mixed Interview Gauntlet covering SQL, statistics, analytics case, behavioral ethics, dashboard choice and executive communication
- evidence-backed editable resume bullet builder
- portfolio project cards generated from strongest Boss Case and capstone evidence
- graduation eligibility gates
- locally generated completion certificate with Open/Share and browser Print → Save as PDF
- explicit certificate disclaimer that DataQuest completion is a training credential, not an accredited academic qualification
- 94-test verified regression suite

### Job Readiness formula

XP is intentionally excluded from Job Readiness.

- skill foundation: 50%
- interviews: 15%
- Boss Cases: 10%
- immutable evidence quality/breadth: 10%
- career/company completion: 5%
- final capstone: 10%

Graduation currently requires:
- all five company chapters complete
- final capstone at least 80/100
- Job Readiness Score at least 80/100
- Interview Gauntlet at least 75/100
- no core readiness domain below 65%

Earlier systems remain available: Practice Gym, adaptive review, SQL Workstation, Python/Pandas Lab, Dashboard Decision Lab, Interview Mode, Daily Challenge, Performance Reviews, company-aware Boss Cases, local reminders, notification deep-links, immutable evidence history and portfolio export/share.

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

The complete five-company career game, final capstone, Job Readiness calculations, Interview Gauntlet, resume suggestions, certificate eligibility, synthetic datasets, SQL execution, guided Pandas simulator, mastery, Boss Cases, evidence history, reminder preferences and portfolio generation work locally.

Resume suggestions only describe recorded DataQuest synthetic training evidence and scores. They do not invent real employer impact.

The portfolio and certificate are lightweight local HTML artifacts. They can be opened or shared from the app and converted to PDF through the browser's **Print → Save as PDF** workflow without shipping a heavyweight PDF engine.
