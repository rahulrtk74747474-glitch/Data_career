# DataQuest: Analyst Career — Progress Log

> Future development must read this file first and continue from the exact next phase. Do not silently rewrite completed phases.

## Product constants

- Framework: Flutter, Android first.
- Architecture direction: clean feature-based architecture.
- State management: Riverpod.
- Offline-first: core lessons, content packs, grading and progress must work with no internet.
- Content format: versioned JSON packs so new tasks can be added without changing Dart code where possible.
- Learning loop: learn → try → fail safely → hint → explanation → retry.
- Hint rule: 3 levels; do not reveal the full solution first.
- Career ladder: Intern → Junior → Analyst → Senior → Lead → Head of Analytics.
- Company progression: e-commerce → SaaS → bank → hospital → logistics.
- Target devices: low-end Android phones, including 2 GB RAM devices.

## Phase 1 — Playable vertical slice

Status: **IMPLEMENTED**

## Phase 2 — Offline analyst workstation and skill model

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #6)**

## Phase 3 — Practice Gym, adaptive review and Boss Case

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #8)**

## Phase 4 — Python/Pandas Lab, dashboard decisions and portfolio evidence

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #10)**

Implemented:
1. Added an offline guided Python/Pandas simulator without bundling a heavy Python runtime.
2. Added six dataframe challenges across Beginner, Intermediate and Advanced.
3. Added Pandas workflows for filtering, missing-value handling, groupby aggregation, sorting/top-N, derived ratios and filter+aggregate.
4. Added a dedicated persistent Python/Pandas mastery skill through SQLite migration.
5. Added Dashboard Decision Lab covering chart choice, KPI design, visual critique and executive hierarchy.
6. Added persistent `task_performance` evidence with best score, attempt count and last completion time.
7. Added Portfolio Evidence screen combining strongest ticket/lab work with Boss Case results.
8. Added offline portfolio summary export via clipboard.
9. Expanded Practice Gym with skill filtering and additional Beginner/Intermediate/Advanced tasks.
10. Migrated SQLite schema to version 3 without deleting prior career, mastery or Boss Case data.
11. Added automated tests for Pandas-style grading, task-performance persistence and portfolio calculations.
12. CI run #10 passed static analysis, all 23 tests, Android debug APK build, and artifact upload.

### Phase 4 technical choice

- Pandas is implemented as a guided simulator: learner code must contain the requested Pandas operation pattern, while equivalent dataframe operations execute locally in Dart.
- This deliberately avoids shipping CPython/NumPy/Pandas binaries into the Android APK and protects low-end-device performance.

## Phase 5 — Interview Mode, Daily Challenge and career progression

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #56)**

Implemented:
1. Added offline Interview Mode with SQL, statistics, analytics case and behavioral rounds.
2. Added timed and untimed interview practice using the same question banks and scoring rules.
3. SQL interview answers execute against the real local SQLite database and use result-set grading.
4. Case and behavioral answers use weighted offline rubrics with criterion-level feedback.
5. Added persistent interview performance: best score, latest score, attempts and last mode.
6. Added deterministic, data-driven Daily Challenge rotation.
7. Added consecutive-day Daily Challenge streaks and one-time daily bonus XP.
8. Changed promotion behavior so XP makes the player eligible but does not automatically promote new progress.
9. Added transparent Performance Review gates using XP, completed career tickets, average attempted-skill mastery, Boss Case evidence and later interview readiness.
10. Legacy saves without a career level migrate from their previous XP-derived role to avoid demotion.
11. Promotion to Data Analyst unlocks SaaS Growth Co.
12. Added SaaS-specific retention, SQL/MRR-proxy, experiment and NRR practice.
13. Added company/role-aware Career Mode ticket filtering and difficulty mixes.
14. Migrated SQLite schema to version 4 with `interview_results` while preserving earlier progress.
15. Added automated tests for promotion gates, Daily Challenge selection, company/role task routing, interview scoring and interview-result persistence.
16. CI run #56 passed static analysis, all 35 tests, Android debug APK build, and artifact upload.

### Phase 5 technical notes

- Free-text interview grading is local rubric/keyword scoring, not cloud/LLM grading, to preserve offline operation.
- Daily Challenge reuses the production ticket graders rather than maintaining a separate answer engine.
- Existing XP, completed tickets, mastery, Boss Case results and portfolio evidence are preserved.

## Phase 6 — Bank progression, multi-company Boss Cases and evidence export

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #94)**

Implemented:
1. Added company progression from SaaS to **NorthStar Bank Analytics** at Lead Analyst.
2. Added SQLite v5 synthetic banking tables: `bank_accounts`, `loan_portfolio` and `bank_transactions`.
3. Added advanced bank career tickets for credit exposure SQL, transaction-review operations, review-workload SQL and credit-governance reasoning.
4. Banking review flags are explicitly treated as prioritization signals, not confirmed fraud labels.
5. Added separate company-aware Boss Cases for e-commerce, SaaS and banking.
6. Added company-aware Boss Case selection using career level and current company.
7. Expanded Daily Challenge rotation with additional SaaS and banking challenges.
8. Added an advanced Bank Analytics Interview covering SQL, review-signal interpretation and portfolio-delinquency case reasoning.
9. Final bank-stage promotion readiness uses the dedicated `bank_analytics` interview result.
10. Added append-only `evidence_attempts` history for successful task/lab, interview and Boss Case attempts.
11. Existing best/latest summary tables remain intact while repeated attempts are preserved individually.
12. Evidence rows record source, score, mode, company and completion time.
13. Explicit full career reset is the only normal in-app path that clears the evidence ledger.
14. Expanded Portfolio Evidence with attempt count, average attempt score and chronological attempt history.
15. Added local HTML portfolio export with print CSS and browser **Print → Save as PDF** workflow.
16. Expanded text portfolio summaries with company and recent attempt history.
17. Extended Lead Analyst → Head of Analytics ticket gate to the current banking content bank.
18. Added automated tests for bank unlocks, bank task routing, company-aware Boss Cases, banking SQLite results, immutable task/interview evidence, portfolio export and Phase 6 JSON content.
19. CI run #94 passed static analysis, all **47 tests**, Android debug APK build, and artifact upload.

### Phase 6 technical notes

- All banking data is synthetic training data; no real customer or financial institution data is bundled.
- `review_flag` represents items routed for review. It is intentionally not modeled as proof of fraud.
- Credit-risk exercises focus on aggregation, validation, governance and decision-quality reasoning rather than automatic individual adverse decisions.
- The portfolio report is generated entirely on-device as HTML and is print-styled for PDF conversion in a browser.
- Immutable evidence is append-only during normal gameplay; best-score tables remain separate summaries for fast UI access.
- SQLite v5 adds new tables without deleting Phase 1–5 progress.

## Phase 7 — Independent company chapters, Hospital Analytics and reminders

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #134)**

Implemented:
1. Decoupled persistent company-chapter progression from the career role ladder.
2. Existing saves without a company chapter migrate to the company already implied by their Phase 6 role, avoiding regression or demotion.
3. Added a dedicated **Company Chapter Review** with evidence gates independent of promotion.
4. Added explicit bank → **Harborview Hospital Analytics** progression while retaining the player's current role, including Head of Analytics.
5. Reserved Logistics Network Co. for Phase 8 so players cannot enter an empty chapter.
6. Migrated SQLite to version 6 without deleting previous career, mastery, interview, Boss Case or evidence data.
7. Added aggregate synthetic `hospital_daily_ops` data for arrivals, completed visits, staffed/occupied capacity, average wait and cancellations.
8. Added synthetic `hospital_capacity_forecast` data for demand-versus-capacity planning.
9. Added seven Advanced Hospital Analytics career tickets spanning SQL, cleaning, statistics, forecasting, operational cohorts, capacity planning and executive communication.
10. Added a hospital-specific end-to-end Boss Case covering data quality, real SQLite grading, wait-time KPI interpretation, visual choice and operational recommendation.
11. Added five hospital Daily Challenge entries.
12. Added a company-gated Hospital Operations Analytics Interview with SQL, forecast interpretation and rubric-scored operations case work.
13. Added company metadata to interview rounds and filtered company-specific interviews by the active chapter.
14. Expanded the SQL Workstation to expose bank and hospital learning tables.
15. Added user-controlled local reminders for Daily Challenge and Review Queue.
16. Reminder preferences and selected clock times persist offline in SharedPreferences.
17. Added a pure reminder-schedule planner so scheduling behavior can be tested independently of Android notification APIs.
18. Added local Android notification scheduling with device timezone support and inexact daily scheduling.
19. Notification permission is requested only when the player enables at least one reminder; disabling all reminders cancels the known schedules.
20. Added a checked-in Android wrapper configuration script and CI step for scheduled-notification receivers, reboot rescheduling, desugaring, Java 17 and multidex.
21. Added automated tests for chapter migration/gates, hospital task routing, hospital Boss Case routing, hospital SQLite results, capacity forecasts, hospital content packs, SQL schema exposure and reminder planning.
22. CI run #134 passed Android wrapper generation/configuration, static analysis, all **62 tests**, Android debug APK build and artifact upload.

### Phase 7 technical notes

- Company chapter is now a separately persisted dimension from `careerLevel`; promotions never silently move the player into a new industry chapter.
- Bank → hospital requires Head of Analytics, current-bank ticket evidence, mastery, the bank Boss Case and the bank interview.
- Hospital data is aggregate synthetic operations data only. The app contains no real PHI, patient identifiers, diagnosis data, treatment advice or clinical decision support.
- Hospital analytics exercises explicitly separate operational signals from clinical conclusions.
- Reminder scheduling uses the device timezone and Android inexact scheduling; DataQuest does not request exact-alarm access.
- The Android wrapper remains generated rather than committed, so `tool/configure_android_notifications.dart` must run after `flutter create`.
- Phase 7 preserves the offline-first design. The notification system is local and does not require cloud services.

## Known Phase 7 limitations

- Logistics Network Co. exists in the chapter model but is intentionally locked until its content is built.
- Hospital content is an initial compact operations curriculum, not a clinical analytics product.
- Reminder taps do not yet deep-link directly into the Daily Challenge or Review Queue.
- Android inexact scheduling can deliver notifications near, rather than exactly at, the selected time.
- Portfolio export remains local HTML/PDF-ready rather than a native one-tap PDF/share flow.
- Free-text interview grading remains local rubric/keyword based.
- Cloud save, leaderboards and multi-device synchronization remain optional future work.

## Phase 8 — Logistics Analytics and company-journey completion

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #167)**

Implemented:
1. Added Hospital → **Logistics Network Co.** unlock through the independent Company Chapter Review.
2. Kept the role ladder unchanged; Head of Analytics can continue into Logistics without an artificial seventh role.
3. Added separately persisted `companyJourneyCompleted` state after the final Logistics evidence review.
4. Migrated SQLite to version 7 without deleting earlier career, mastery, interview, Boss Case or evidence data.
5. Added synthetic `logistics_shipments` data covering routes, promised/actual transit hours, weight, status and shipping cost.
6. Added synthetic `logistics_inventory_flow` data for warehouse inbound/outbound flow, ending inventory and capacity.
7. Added synthetic `logistics_throughput_forecast` data for day-of-week demand and planned throughput.
8. Added ten Advanced Logistics Analytics career tickets covering SQL, cleaning, statistics, SLA, throughput gaps, warehouse utilization, normalized cost, route cohorts, delay-driver analysis, forecasting and executive communication.
9. Added a Logistics-specific end-to-end Boss Case with data-quality controls, real SQLite route-SLA grading, KPI interpretation, chart choice and executive recommendation.
10. Added five Logistics Daily Challenge entries.
11. Added a chapter-gated Logistics Analytics Interview with SQL, forecast interpretation and a rubric-scored network decision case.
12. Added Logistics tables to the SQL Workstation.
13. Extended company-specific interview evidence so Hospital → Logistics uses the hospital interview and the final Logistics review uses the logistics interview.
14. Added the final five-company completion experience while leaving all Practice, Daily, Interview, Boss Case and Portfolio modes available afterward.
15. Added notification payload routing for Daily Challenge and Review Queue.
16. Reminder taps now deep-link to the correct screen, including launches where the notification opened the app from a stopped state.
17. Reminder initialization is non-blocking so unsupported/test platforms cannot prevent the offline app from starting.
18. Added native portfolio **Open report** and **Share report** actions using the generated local HTML evidence report.
19. Kept browser **Print → Save as PDF** as the PDF workflow instead of bundling a heavyweight PDF engine into the low-end-device app.
20. Added automated tests for Hospital→Logistics gates, final journey persistence, Logistics task/Boss routing, Logistics SQLite calculations, content packs, SQL schema exposure and notification destinations.
21. CI run #167 passed Android wrapper generation/configuration, static analysis, all **77 tests**, Android debug APK build and artifact upload.

### Phase 8 technical notes

- Logistics content uses synthetic operational data only.
- Route-level SLA differences are taught as investigation signals, not proof that a route code itself causes delay.
- Forecasting exercises explicitly use seasonality, error validation and scenario ranges rather than deterministic forecasts.
- Final company-journey completion is persisted independently from both career role and active company chapter.
- Notification deep-links use the existing local notification payloads; no cloud messaging is required.
- Portfolio Open/Share adds native device delivery while retaining a lightweight HTML report.
- Native PDF generation was evaluated but not added in this phase because the HTML → browser Print/Save-as-PDF workflow provides the output without adding a larger PDF-rendering dependency.
- SQLite v7 preserves all Phase 1–7 progress.

## Known Phase 8 limitations

- The five-company journey is complete; there are no additional industry chapters yet.
- Logistics is a compact training curriculum rather than a full transportation-management system.
- Free-text interview grading remains local rubric/keyword based.
- Portfolio PDF still relies on the device/browser print flow rather than a one-tap native PDF generator.
- Cloud save, leaderboards and multi-device synchronization remain optional future work.
- Resume and graduation/certification workflows are not yet generated from the evidence ledger.

## Phase 9 — Graduation & Job Readiness

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #209)**

Implemented:
1. Migrated SQLite to version 8 while preserving all Phase 1–8 career, mastery, company, interview, Boss Case and immutable evidence data.
2. Added a synthetic cross-company `capstone_company_kpis` dataset covering baseline/current service, cost, volume and exception metrics across all five company chapters.
3. Added the six-part **Board Portfolio Performance Capstone** covering data validation, real SQLite, statistical interpretation, KPI calculation, dashboard choice and executive recommendation.
4. Added persistent `capstone_results` plus append-only capstone attempts in the immutable evidence ledger.
5. Capstone component performance updates cleaning, SQL, statistics and business mastery using the existing adaptive skill model.
6. Added a transparent **Job Readiness Score** that intentionally excludes XP.
7. Job Readiness weighting is: skill foundation 50%, interviews 15%, Boss Cases 10%, immutable evidence quality/breadth 10%, career/company completion 5%, and final capstone 10%.
8. Added readiness breakdowns for SQL, spreadsheets/cleaning, statistics, Python/Pandas, business communication and interviews.
9. Added targeted remediation recommendations when a domain or evidence category is below the readiness target.
10. Added the 15-minute **Final Interview Gauntlet** mixing real SQLite, statistics, analytics case structure, behavioral ethics, dashboard choice and executive communication.
11. The Interview Gauntlet is gated to the final company stage and uses the existing offline interview grading/persistence engine.
12. Added an evidence-backed **Resume Bullet Builder** with editable text and clipboard export.
13. Resume suggestions describe recorded DataQuest synthetic training exercises and scores only; they do not invent employer impact or unsupported achievements.
14. Added portfolio project cards generated from strongest Boss Case and capstone evidence, including company, score, skills and attempt count.
15. Added the project-card section to both the in-app Portfolio screen and exported local HTML portfolio.
16. Added evidence-based graduation rules requiring the five-company journey, capstone >=80, Job Readiness >=80, Interview Gauntlet >=75 and no core readiness domain below 65%.
17. Added a lightweight local HTML completion certificate with learner-entered display name, readiness/capstone scores, Open/Share actions and browser Print → Save as PDF support.
18. Certificate output explicitly states that it is a DataQuest training completion certificate and not an accredited academic credential.
19. Added the final capstone dataset to SQL Workstation.
20. Full career reset now also clears capstone summary results while preserving the existing explicit-reset semantics for immutable evidence.
21. Added automated tests for capstone scoring and SQLite results, Job Readiness calculations, XP exclusion, remediation, graduation gates, capstone persistence/evidence, mixed Interview Gauntlet scoring, resume transformations, project cards, certificate output/escaping and Phase 9 content.
22. CI run #209 passed Android wrapper generation/configuration, static analysis, all **94 tests**, Android debug APK build and artifact upload.

### Phase 9 technical notes

- Job Readiness is evidence-based; XP does not directly contribute to the score.
- The largest readiness weight is skill mastery so repeated demonstrated competence matters more than progression points.
- Immutable evidence scoring uses best score per distinct source plus evidence breadth and company breadth.
- The final capstone remains fully offline and uses the same read-only SQLite runner as production learning tasks.
- Resume text is deliberately framed as synthetic training evidence rather than professional-employment claims.
- The Interview Gauntlet reuses the existing interview engine instead of creating a second scoring system.
- Certificate generation remains lightweight HTML to protect APK size and low-end-device performance.
- SQLite v8 preserves all earlier progress through normal migration.

## Known Phase 9 limitations

- Job Readiness is a transparent training heuristic, not a guarantee of employment or an external certification score.
- Free-text interview answers still use local keyword/rubric scoring rather than semantic LLM grading.
- The completion certificate is not an accredited academic or professional credential.
- Resume bullets are locally generated suggestions and still require the learner to tailor them to a real resume.
- Portfolio/certificate PDF conversion still uses the device browser print workflow.
- Progress is still device-local unless the user manually preserves the app data; cloud continuity is not implemented yet.
- Weekly online cases and leaderboards remain optional future capabilities.

## Phase 10 — Production hardening, portable backups and optional cloud continuity

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #257)**

Implemented:
1. Bumped the application to **DataQuest v1.0.0+10**.
2. Added a versioned portable DataQuest backup format with explicit format identifier, schema version, creation timestamp and source app version.
3. Portable backups include career progress, reminder settings, skill mastery, placement results, Boss Case summaries, task performance, interview results, capstone summaries and immutable evidence attempts.
4. Synthetic curriculum/dataset tables are deliberately excluded from backups because the application can recreate them from the checked-in curriculum.
5. Added strict backup validation before restore.
6. Backups from unsupported newer schemas are rejected before any mutation.
7. SQLite player-state restoration is executed inside one transaction.
8. Added a safety-snapshot rollback layer across SQLite plus SharedPreferences-backed progress/reminders so a failure after database restore cannot leave partially restored player state.
9. Added Data & Cloud UI for creating/sharing backups and selecting/restoring JSON backup files.
10. Added an explicit offline-first `CloudSyncGateway` abstraction so the core app has no cloud dependency.
11. Added an optional Supabase REST gateway configured only through compile-time `--dart-define` values; no project URL, public key, password or access token is committed.
12. Added explicit session-only cloud sign-in and account creation. DataQuest does not persist the email password or access token.
13. Added checked-in optional Supabase RLS/database setup in `docs/supabase_phase10.sql`.
14. Added deterministic local/cloud conflict resolution instead of a last-write-wins overwrite.
15. Merge rules preserve the more advanced career/company state, union completed task/day sets, select stronger/newer summary evidence and deduplicate immutable evidence attempts.
16. Added optional cloud backup download → deterministic merge → upload flow.
17. Added an optional privacy-conscious leaderboard.
18. Leaderboard publication accepts a player-chosen 3–20 character alias and publishes only user ID, alias, Job Readiness Score, graduation flag and update timestamp.
19. Leaderboard payloads explicitly exclude email, evidence contents and company-history fields.
20. Added versioned remote Weekly Analyst Case delivery.
21. Remote weekly packs are schema-validated before becoming playable.
22. Valid online weekly packs are cached locally.
23. Remote outage or invalid/newer schema falls back first to the last valid cache and then to a bundled offline weekly case.
24. Added a Weekly Analyst Case screen with source status and manual refresh.
25. Added a dedicated Release Diagnostics screen showing app version, SQLite schema, backup schema, content-schema summary, weekly schema, cloud/feed configuration state and last backup/restore timestamp.
26. Diagnostics never display cloud keys, passwords, access tokens or evidence contents.
27. Added Internet permission to the generated Android main manifest so optional cloud/weekly features work in release mode while the core remains offline-first.
28. Added accessibility regression coverage using Android tap-target and labeled-tap-target guidelines.
29. Added a source content-asset budget capped at 5 MB; the verified v1.0 curriculum is only **0.12 MB**.
30. Expanded CI to build and verify both the debug APK and production-mode Android App Bundle.
31. Added per-ABI release APK builds for ARM32, ARM64 and x86_64 so direct-install size is measured rather than inferred from the all-architecture debug APK.
32. Added CI artifact-size budgets and build-summary reporting.
33. Verified sizes in run #257: debug APK **162.10 MB** (development artifact), release AAB **53.24 MB**, ARM32 release APK **16.98 MB**, ARM64 release APK **19.34 MB**, x86_64 release APK **20.76 MB**, content assets **0.12 MB**.
34. Added automated coverage for backup round-trips, newer-schema rejection, mid-restore rollback, deterministic conflict merging, mocked network cloud sync, weekly-case online/cache/schema fallback, leaderboard privacy, alias validation, accessibility and low-memory content budgets.
35. CI run #257 passed dependency resolution, Android wrapper generation/configuration, static analysis, all **107 tests**, debug APK build, release AAB build, all three split release APK builds, release-size budgets and all artifact uploads.

### Phase 10 technical notes

- Flutter's official Android guidance recommends app bundles for Play delivery and split-per-ABI APKs for direct APK distribution; the CI now verifies both production formats.
- The all-architecture debug APK is intentionally treated as a development artifact and has a separate budget because it is not representative of an end-user release download.
- DataQuest remains fully usable when Supabase and the remote weekly-case URL are absent.
- Cloud configuration uses `DATAQUEST_SUPABASE_URL`, `DATAQUEST_SUPABASE_ANON_KEY` and optional `DATAQUEST_WEEKLY_CASE_URL` compile-time defines.
- Cloud merge is deterministic and designed to avoid silently replacing a more advanced career state with a less advanced copy.
- Reminder settings remain local-preferred during a cloud merge; a portable explicit backup/restore can transfer reminder preferences.
- Cloud authentication is session-only; users sign in again after an app restart instead of storing a long-lived credential in Phase 10.
- Weekly content never replaces the cached pack unless it parses against the supported schema.
- Release diagnostics are intentionally safe for screenshots/support and omit secrets.
- The CI release AAB/APKs verify compilation and size. A real Play Store publication must still use the owner's production signing keystore and normal Play Console release process.

## Known v1.0 operational limitations

- Optional cloud save and leaderboard require the owner to provision/configure a Supabase project and run the checked-in RLS schema.
- Supabase email-confirmation behavior depends on the selected project's Auth configuration.
- No cloud configuration is shipped by default; this is intentional so the repository contains no backend identifiers/credentials and offline use remains the default.
- The remote Weekly Case feed requires the owner to host a JSON endpoint; bundled/cache fallback works without it.
- Free-text interview scoring remains deterministic local rubric/keyword grading rather than semantic LLM grading.
- Portfolio/certificate PDF conversion still uses the device/browser Print → Save as PDF workflow.
- CI checks accessibility semantics and content/release size budgets, but it does not replace hands-on testing on representative physical 2 GB RAM Android hardware.
- Store production signing, Play Console privacy declarations, screenshots/listing copy and staged rollout are release-operations tasks rather than game-development phases.

## Roadmap status — v1.0 complete

**All defined development phases (Phase 1 through Phase 10) are implemented.**

There is no defined Phase 11 in the current roadmap. Future work is maintenance/product expansion rather than an incomplete phase. Appropriate post-v1.0 backlog items include physical-device QA, production signing/Play internal testing, additional content packs, more industries, richer semantic interview feedback, or a managed weekly-content publishing workflow.

Future maintenance must continue to preserve:
- offline-first core gameplay
- migration-safe player progress
- immutable evidence integrity
- explicit opt-in for online features
- privacy-safe leaderboard fields
- low-end Android performance budgets

## Ready progress-log line for this phase

`2026-10-06 — Phase 10 / v1.0: Added rollback-safe portable backups, optional deterministic Supabase cloud continuity, cached weekly cases, alias-only leaderboard, release diagnostics, accessibility/low-memory gates, and verified AAB + per-ABI release artifacts.`
