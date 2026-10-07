# DataQuest: Analyst Career

## v1.1 expansion documentation

- `docs/GAME_DESIGN_DOCUMENT_v1_1.md` — story, company timeline, career map, scoring, formulas, content targets and 12-week roadmap.
- `docs/FLUTTER_SETUP_AND_ARCHITECTURE_v1_1.md` — Android Studio/Codespaces setup, exact commands, package purposes, folder architecture, theme, splash and navigation.

DataQuest is an offline-first Flutter game that trains a learner for real data-analyst work through realistic company tickets, datasets, interviews, performance reviews, company chapters, evidence, graduation and job-readiness practice.

## Current build: v1.0 — Phase 10 complete

The complete defined roadmap is implemented through **Phase 10**.

Core journey:
- E-commerce Co.
- SaaS Growth Co.
- NorthStar Bank Analytics
- Harborview Hospital Analytics
- Logistics Network Co.
- Final cross-company analyst capstone
- Interview Gauntlet
- Job Readiness & Graduation
- Portable backup / restore
- Optional cloud continuity
- Weekly case delivery with offline fallback
- Privacy-safe alias leaderboard

### Phase 10 production capabilities

- versioned portable JSON Backup & Restore
- backups cover career progress, mastery, placement, task performance, interviews, Boss Cases, capstone summaries, immutable evidence and reminder preferences
- synthetic curriculum datasets are not copied into backups; the app recreates them locally
- imported backups are schema-validated before mutation
- unsupported/newer backup schemas are rejected safely
- SQLite restore is transactional
- restore uses an in-memory safety snapshot and rolls SQLite plus SharedPreferences-backed progress/reminders back if a later persistence step fails
- backend-agnostic optional cloud-sync gateway
- optional Supabase REST implementation configured only through `--dart-define`
- explicit session-only email/password sign-in and account creation; passwords and access tokens are not persisted by DataQuest
- deterministic local/cloud conflict resolution instead of last-write-wins
- immutable evidence attempts are deduplicated during merge
- optional alias-only leaderboard publishing readiness score, graduation flag and update time only
- no email, evidence details or company-history fields are published to the leaderboard
- versioned Weekly Analyst Case delivery
- remote weekly content is schema-validated before use
- last valid weekly pack is cached locally
- invalid/offline remote content falls back to cache and then to a bundled offline case
- dedicated Release Diagnostics screen showing safe app/database/content/backup status without exposing keys, passwords or tokens
- Android release manifest includes Internet permission for optional online services while the core remains fully offline
- release accessibility regression tests
- low-memory bundled-content budget
- production AAB verification
- per-ABI release APK verification
- CI size budgets and artifact reporting

## Verified v1.0 release gate

GitHub Actions run #257 passed:
- dependency resolution
- Android wrapper generation/configuration
- static analysis
- **107/107 automated tests**
- debug APK build
- release AAB build
- ARM32, ARM64 and x86_64 release APK builds
- release-size budgets
- debug APK upload
- release AAB upload
- split release APK upload

Measured build outputs:
- debug APK: **162.10 MB** — development-only multi-runtime artifact
- release AAB: **53.24 MB**
- ARM32 release APK: **16.98 MB**
- ARM64 release APK: **19.34 MB**
- x86_64 release APK: **20.76 MB**
- bundled content assets: **0.12 MB**

The split release APKs are the better direct-install size reference. Flutter/Google Play app bundles can deliver architecture-specific content rather than the all-architecture debug payload.

## Job Readiness formula

XP is intentionally excluded from Job Readiness.

- skill foundation: 50%
- interviews: 15%
- Boss Cases: 10%
- immutable evidence quality/breadth: 10%
- career/company completion: 5%
- final capstone: 10%

Graduation requires:
- all five company chapters complete
- final capstone at least 80/100
- Job Readiness Score at least 80/100
- Interview Gauntlet at least 75/100
- no core readiness domain below 65%

## Offline-first guarantee

Without internet or cloud configuration, DataQuest still supports:
- the complete five-company career
- all bundled lessons and synthetic datasets
- Practice Gym and adaptive review
- SQL Workstation
- guided Python/Pandas Lab
- Dashboard Decision Lab
- Daily Challenge
- bundled/cached Weekly Case
- Interview Mode and Interview Gauntlet
- Performance Reviews and Company Chapter Reviews
- company-aware Boss Cases
- final capstone
- Job Readiness calculations
- graduation eligibility
- resume suggestions
- portfolio/certificate generation and sharing
- local reminders
- portable backup/restore

Cloud save, online weekly cases and leaderboard are optional enhancements.

## Optional online configuration

No cloud endpoint or credential is committed to this repository.

To enable optional Supabase continuity:

```bash
flutter run \
  --dart-define=DATAQUEST_SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=DATAQUEST_SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Run `docs/supabase_phase10.sql` in the selected Supabase project first.

To additionally enable a remote weekly case feed:

```bash
--dart-define=DATAQUEST_WEEKLY_CASE_URL=https://example.com/dataquest-weekly.json
```

The weekly endpoint must return the supported versioned JSON schema; invalid/newer content is rejected before it becomes playable.

## Run locally

The Android wrapper is generated on demand in this repository. After generating it, apply the checked-in Android configuration script:

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

## Build Android release artifacts

Google Play / bundle:

```bash
flutter build appbundle --release
```

Direct-install release APKs by CPU architecture:

```bash
flutter build apk --release --split-per-abi
```

## Evidence and credential integrity

Resume suggestions only describe recorded DataQuest synthetic training evidence and scores. They do not invent real employer impact.

The DataQuest certificate is a training-completion credential, not an accredited academic or professional qualification.

Portfolio and certificate files are lightweight local HTML artifacts. They can be opened/shared from the app and converted to PDF through the browser's **Print → Save as PDF** workflow without bundling a heavyweight PDF renderer.

Read `PROGRESS_LOG.md` before future maintenance changes.

## v1.1 expansion documentation

- Full game design and MVP content matrix: `docs/GAME_DESIGN_DOCUMENT_v1_1.md`
- Flutter setup, Android Studio/Codespaces bootstrap, architecture, splash and navigation: `docs/FLUTTER_SETUP_v1_1.md`
