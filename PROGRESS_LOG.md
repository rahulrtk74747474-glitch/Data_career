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

## Known Phase 6 limitations

- Company progression currently reaches banking; hospital and logistics chapters remain future work.
- The career role ladder ends at Head of Analytics, so later company chapters need company progression decoupled from role level.
- HTML export is PDF-ready but is not yet a native one-tap PDF file.
- Banking content is an initial compact synthetic pack rather than a full bank analytics curriculum.
- Free-text interview grading remains local rubric/keyword based.
- Cloud save, leaderboards and multi-device synchronization remain optional future work.

## Exact next step — Phase 7

**Decouple company chapters from the role ladder and add the Hospital Analytics chapter.**

Phase 7 should:
1. Add persistent company-chapter progression independent of career role so players can continue after Head of Analytics.
2. Add bank → hospital chapter unlock requirements without changing the existing role ladder.
3. Add safe synthetic hospital operations data only—patient-flow, capacity, waiting-time, scheduling and quality metrics; no real PHI and no diagnosis/treatment advice.
4. Add hospital SQL, cleaning, statistics, operations and executive-communication tickets.
5. Add a hospital-specific Boss Case, Daily Challenges and interview/case content.
6. Add richer cohort/forecasting and capacity-planning exercises appropriate to operational analytics.
7. Add local notification support for Daily Challenge/review reminders with user-controlled settings.
8. Add automated tests for independent company-chapter unlocks, hospital content, Boss Case routing and notification scheduling abstraction.
9. Preserve offline-first operation, synthetic data and low-end Android performance.

Do not start Phase 8 until Phase 7 is explicitly requested or Phase 7 is complete and the user asks to continue.

## Ready progress-log line for this phase

`2026-10-06 — Phase 6: Added Lead Analyst banking progression, synthetic risk/fraud-review/credit analytics, company-aware Boss Cases, expanded Daily/interview content, immutable attempt history, and local HTML/PDF-ready portfolio export.`
