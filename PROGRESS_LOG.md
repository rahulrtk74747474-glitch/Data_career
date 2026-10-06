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

## Exact next step — Phase 8

**Build the Logistics Analytics chapter and complete the current company journey.**

Phase 8 should:
1. Add hospital → Logistics Network Co. unlock requirements using the independent company-chapter review system.
2. Add safe synthetic logistics data for shipments, warehouses, routes, SLA performance, delays, inventory flow and operating cost.
3. Add logistics SQL, cleaning, statistics, forecasting, cohort/route, cost and executive-communication tickets.
4. Add a logistics-specific Boss Case, Daily Challenges and interview/case content.
5. Add network-capacity, SLA, delay-driver and demand/throughput forecasting exercises.
6. Add a company-journey completion experience after Logistics while leaving the career role ladder unchanged.
7. Add notification-tap routing to the relevant Daily Challenge or Review Queue screen.
8. Improve portfolio delivery with a share/open workflow and evaluate native PDF export without compromising low-end-device performance.
9. Add automated tests for hospital→logistics unlocks, logistics datasets/content, Boss Case routing, notification destinations and final company-journey completion.
10. Preserve offline-first operation, synthetic data and low-end Android performance.

Do not start Phase 9 until Phase 8 is explicitly requested or Phase 8 is complete and the user asks to continue.

## Ready progress-log line for this phase

`2026-10-06 — Phase 7: Decoupled company chapters from career roles, added synthetic Hospital Analytics operations/capacity training with Boss/Daily/Interview content, and added user-controlled local Daily/Review reminders.`
