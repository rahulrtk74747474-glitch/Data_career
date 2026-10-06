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

Implemented:
- Flutter app shell with Material 3 light/dark themes.
- Riverpod app state.
- Offline career progress persistence with SharedPreferences.
- Career dashboard showing role, XP and company metrics.
- Data-driven JSON task loader.
- Spreadsheet, SQL and statistics/communication starter tickets.
- Progressive hints, retry, scoring and explanations.

## Phase 2 — Offline analyst workstation and skill model

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #6)**

Implemented:
- Real local SQLite with seeded campaign and messy customer datasets.
- Actual read-only SQL execution and result-set grading.
- Placement testing across five core analyst skills.
- Persistent mastery, weak-topic tracking and 1/3/7-day review scheduling.
- Skill radar.
- Messy data-cleaning ticket.
- Tests for SQLite, grading, mastery and app launch.

## Phase 3 — Practice Gym, adaptive review and Boss Case

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #8)**

Implemented:
1. Added Practice Gym organized by skill and difficulty.
2. Added adaptive review queue using due dates and mastery priority.
3. Added home-screen recommendations from weakest unfinished skills.
4. Added SQL schema browser and reusable read-only scratchpad.
5. Migrated SQLite schema from v1 to v2 without deleting Phase 2 progress.
6. Added `customers` and `orders` learning tables.
7. Added real SQLite JOIN ticket.
8. Added real filtering + aggregation ticket.
9. Added first weekly Boss Case combining cleaning → SQL → KPI → chart → executive recommendation.
10. Added weighted 100-point Boss Case rubric.
11. Added persistent `boss_case_results` performance record.
12. Boss Case component performance updates skill mastery.
13. Added automated tests for adaptive review priority, recommendations, SQL schemas/queries, Boss Case scoring and Boss Case persistence.\n14. CI run #8 passed static analysis, all 16 tests, Android debug APK build, and artifact upload.

### Content schema migration

- Ticket schema version 3 adds optional `difficulty`.
- v1/v2 ticket packs remain readable and default to Beginner.
- Boss Cases are stored in a separate versioned JSON definition.
- Core learning content remains data-driven and offline.

## Known Phase 3 limitations

- Practice Gym currently uses the existing ticket library; it does not yet contain large task banks per difficulty.
- Review queue selects one representative task per weak/due skill.
- SQL scratchpad is intentionally read-only and limited to local seeded learning tables.
- Boss Case currently saves the latest score per case rather than a full attempt history.
- Python/Pandas execution is not implemented yet.
- Dashboard-building, portfolio export, Interview Mode and Daily Challenge remain future work.
- Cloud sync and leaderboards remain optional.

## Exact next step — Phase 4

**Build the Python/Pandas Lab + dashboard decision lab + portfolio evidence system.**

Phase 4 should:
1. Add an offline Python/Pandas learning simulator focused on dataframe operations.
2. Add data-manipulation tickets equivalent to common analyst Pandas workflows.
3. Add dashboard/chart selection exercises with KPI design and visual critique.
4. Add a portfolio evidence record containing completed Boss Cases and strongest ticket scores.
5. Add exportable portfolio summaries without requiring cloud sync.
6. Expand Practice Gym task banks across Beginner, Intermediate and Advanced.
7. Add automated tests for Pandas-style grading and portfolio calculations.
8. Preserve low-end Android performance and full offline operation.

Do not start Phase 5 until Phase 4 is explicitly requested or Phase 4 is complete and the user asks to continue.

## Ready progress-log line for this phase

`2026-10-06 — Phase 3: Added Practice Gym, adaptive review/recommendations, SQL schema scratchpad, real JOIN/filter tickets, and the first persisted multi-step Boss Case with weighted scoring.`
