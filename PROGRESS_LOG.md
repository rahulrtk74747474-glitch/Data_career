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
- Reusable ticket model with context, goal, deliverable, hints and grading data.
- Spreadsheet, SQL and statistics/communication starter tickets.
- 3-level progressive hints, retry, scoring and explanations.
- Correct tasks award XP and alter company metrics.

Phase 1 CI note:
- The original Phase 1 CI run failed at static analysis because the formula unit test accidentally interpolated `$D2`, and `flutter create` generated a default `widget_test.dart` referencing `MyApp`.
- Phase 2 fixes both root causes and replaces that default test with a DataQuest-aware widget test.

## Phase 2 — Offline analyst workstation and skill model

Status: **IMPLEMENTED — CI VERIFIED (GitHub Actions run #6)**

Implemented:
1. Added real local SQLite using `sqflite`.
2. Seeded `campaign_performance` and messy `customer_dirty` datasets.
3. Replaced the main SQL ticket's token-only grading with actual read-only SQLite execution and result-set grading.
4. Added SQL safety rules that block mutating statements and multiple statements.
5. Added a five-question placement test covering spreadsheets, SQL, cleaning, statistics and business reasoning.
6. Added persistent `skill_mastery` and `placement_results` tables.
7. Added mastery updates after completed tickets.
8. Added weak-topic detection and score-based spaced review scheduling (1, 3 or 7 days).
9. Added a `fl_chart` radar chart plus skill detail screen.
10. Added an Operations data-cleaning ticket with nulls, duplicates, mixed dates, inconsistent categories, invalid ages and a suspicious negative amount.
11. Added SQLite/result grading/mastery unit tests plus a real app widget smoke test.
12. Updated CI to install SQLite native test support before Flutter tests.\n13. CI run #6 passed static analysis, all 8 tests, Android debug APK build, and artifact upload.

### Content schema migration

- Phase 1 content was upgraded from schema version 1 to schema version 2.
- v2 adds optional fields: `skillKey`, `expectedRows`, and `expectedSelections`.
- The Dart parser keeps defaults for these fields so older v1-style tasks remain readable.
- New content remains data-driven in JSON.

### Technical choice

Phase 2 uses `sqflite` instead of Drift. Both satisfy the product's SQLite requirement; sqflite avoids generated source/build_runner overhead and keeps the first offline workstation smaller and easier to debug on low-end Android devices.

## Known Phase 2 limitations

- The SQL workstation currently exposes the seeded campaign table through task context rather than a full schema browser.
- Data cleaning is a multi-select applied-reasoning task; an editable spreadsheet-like cleaning workspace is not built yet.
- Placement currently has one diagnostic question per core category.
- Spaced repetition calculates due dates and weak topics but does not yet have a dedicated review queue screen.
- Python/Pandas is not yet simulated.
- Practice Gym, Daily Challenge, Boss Case, Interview Mode and Portfolio export are still future phases.
- Cloud sync/leaderboards remain optional future work.

## Exact next step — Phase 3

**Build Practice Gym + adaptive review queue + the first end-to-end Boss Case.**

Phase 3 should:
1. Add a Practice Gym organized by skill and difficulty.
2. Add a due-review queue that prioritizes weak skills from Phase 2 mastery data.
3. Add a schema/table browser and reusable SQL scratchpad.
4. Add at least one JOIN ticket and one filtering/aggregation ticket with real SQLite result grading.
5. Add the first weekly Boss Case combining cleaning → SQL → KPI → chart choice → executive recommendation.
6. Add score rubrics and a saved boss-case performance record.
7. Add basic skill-adaptive task recommendations on the home screen.
8. Preserve full offline functionality and keep content data-driven.
9. Add automated tests for review prioritization and boss-case scoring.

Do not start Phase 4 until Phase 3 is explicitly requested or Phase 3 is complete and the user asks to continue.

## Ready progress-log line for this phase

`2026-10-06 — Phase 2: Added real offline SQLite SQL execution/result grading, messy cleaning practice, placement testing, persistent mastery + spaced review scheduling, skill radar, and expanded CI/tests.`
