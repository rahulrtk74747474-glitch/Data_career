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

Status: **IMPLEMENTED — CI verification pending**

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

### Technical choice

- Pandas is implemented as a guided simulator: learner code must contain the requested Pandas operation pattern, while equivalent dataframe operations execute locally in Dart.
- This deliberately avoids shipping CPython/NumPy/Pandas binaries into the Android APK and protects low-end-device performance.
- Portfolio export is plain structured text copied to the system clipboard, requiring no cloud account or file permission.

## Known Phase 4 limitations

- The Pandas Lab is not an arbitrary Python interpreter; unsupported Python syntax is not executed.
- Portfolio export is text/clipboard rather than PDF or DOCX.
- Only the best/latest evidence is stored, not a full immutable attempt history.
- Dashboard lab uses decision challenges rather than a freeform drag-and-drop dashboard builder.
- Daily Challenge and Interview Mode are not implemented yet.
- Company progression beyond the first e-commerce company is still future work.
- Cloud sync and leaderboards remain optional.

## Exact next step — Phase 5

**Build Interview Mode + Daily Challenge + career/company progression.**

Phase 5 should:
1. Add SQL, statistics, case and behavioral interview rounds with timed/untimed practice.
2. Add data-driven Daily Challenge rotation and streak integration.
3. Add performance-review gates for promotion and progression from e-commerce to SaaS.
4. Add role-specific difficulty and ticket mixes as the player progresses.
5. Add interview feedback rubrics and saved interview performance.
6. Add automated tests for promotion gates, daily challenge selection and interview scoring.
7. Preserve full offline functionality.

Do not start Phase 6 until Phase 5 is explicitly requested or Phase 5 is complete and the user asks to continue.

## Ready progress-log line for this phase

`2026-10-06 — Phase 4: Added guided offline Pandas workflows, dashboard/KPI decision practice, persistent strongest-score evidence, portfolio summary export, and expanded multi-level Practice Gym content.`
