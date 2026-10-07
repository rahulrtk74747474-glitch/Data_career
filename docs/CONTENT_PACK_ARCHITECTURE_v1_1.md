# DataQuest v1.1 — Unified SQLite & Content-Pack Architecture

## Purpose

Expansion Item 3 standardizes how DataQuest stores offline player state and versioned learning content. The design keeps the app fully usable without a network, preserves existing v1.0/v1.1 progress, and lets future task packs be added without changing Dart models for every new lesson.

## Canonical SQLite schema

SQLite schema version: **10**.

### Player/state tables

| Table | Purpose |
| --- | --- |
| `users` | Local learner identity. The default offline user is `local-player`. |
| `progress` | XP, role level, company chapter, daily streak and update time. |
| `attempts` | Append-only task attempts. Stores the task ID plus `task_content_version` so evidence still identifies the version attempted after a pack upgrade. |
| `user_achievements` | Learner-to-achievement unlock ledger. |

Existing specialist state tables from v1.0 remain intact, including mastery, placement, Boss Case, interview, capstone and immutable evidence tables.

### Content catalog tables

| Table | Indexed columns | JSON payload |
| --- | --- | --- |
| `content_packs` | pack ID, schema/content version | No |
| `tasks` | skill, difficulty, company, answer type, pack, active state | Yes |
| `datasets` | name, pack, active state | Yes |
| `dialogues` | trigger, pack, active state | Yes |
| `rubrics` | kind, pack, active state | Yes |
| `events` | event type, pack, active state | Yes |
| `achievements` | title, pack, active state | Rule JSON only |

Catalog rows use stable IDs. Pack upgrades **do not delete rows**. Items removed from a newer pack are marked `is_active = 0`; items still present are updated in place. This preserves foreign-key targets for historical attempts and unlocked achievements.

Achievements now carry `pack_id`, making ownership consistent with every other catalog type. A v9 database adds this column as nullable so pre-existing achievements can migrate without data loss; the first canonical pack containing a legacy achievement can claim it.

## Foreign-key and migration policy

- SQLite foreign keys are enabled on database configure.
- New installs create the complete v10 schema.
- v9 installs upgrade in place by adding lifecycle/ownership/version-snapshot columns.
- No player state is dropped during migration.
- Catalog indexes are added idempotently.
- The only normal destructive reset remains the app's explicit career-reset workflow.

## Content-pack versions

Two independent versions are required:

- `schemaVersion`: structure/contract version understood by the app.
- `contentVersion`: revision number for one `packId`.

DataQuest currently supports content-pack schema versions **1 and 2**. Schema 2 is the canonical v1.1 format. A pack declaring a newer unsupported schema is rejected before any SQLite mutation.

For one `packId`:

1. lower/equal `contentVersion` -> skip,
2. higher `contentVersion` -> transactional upgrade,
3. failed upgrade -> transaction rolls back and the previously installed version remains active.

Primary IDs may not be silently stolen by another pack. A task/dataset/dialogue/rubric/event/achievement already owned by a different pack causes the incoming pack to be rejected.

## Canonical schema-v2 JSON contract

```json
{
  "packId": "industry-sql-core",
  "schemaVersion": 2,
  "contentVersion": 1,
  "datasets": [],
  "rubrics": [],
  "dialogues": [],
  "events": [],
  "achievements": [],
  "tasks": []
}
```

All six collections are arrays in schema v2.

### Task

Required:

```json
{
  "id": "retail-sql-001",
  "title": "Completed Revenue by Region",
  "skillKey": "sql",
  "difficulty": "Beginner",
  "companyKey": "ecommerce",
  "answerType": "sql_result",
  "datasetId": "retail-sales",
  "rubricId": "sql-result-v1",
  "context": "Operations needs a regional revenue cut.",
  "prompt": "Return completed revenue by region.",
  "expectedAnswer": "SELECT ...",
  "expectedRows": [{"region": "North", "revenue": 1200}],
  "hints": ["Filter status.", "Aggregate revenue.", "Group by region."]
}
```

Rules:

- exactly three non-empty hints,
- `datasetId` must exist in the same pack,
- `rubricId` must exist in the same pack,
- at least one of `expectedAnswer`, non-empty `expectedRows`, or non-empty `expectedSelections` must be supplied.

### Dataset

```json
{
  "id": "retail-sales",
  "name": "retail_sales",
  "columns": ["order_id", "region", "revenue"],
  "rows": [{"order_id": "R1", "region": "North", "revenue": 1200}]
}
```

The catalog stores the dataset definition as JSON. A lab may materialize those rows into its local execution surface when needed.

### Rubric

```json
{
  "id": "insight-core-v1",
  "kind": "written_insight",
  "criteria": [
    {"key": "clarity", "weight": 25},
    {"key": "evidence", "weight": 30},
    {"key": "recommendation", "weight": 25},
    {"key": "businessImpact", "weight": 20}
  ]
}
```

Schema-v2 criterion weights must be positive and total 100.

### Dialogue

```json
{
  "id": "manager-good-evidence",
  "triggerKey": "insight_score_80",
  "speaker": "Manager",
  "text": "Good analysis. The evidence supports the recommendation."
}
```

### Random event

```json
{
  "id": "dirty-vendor-file",
  "eventType": "data_quality",
  "title": "Dirty vendor export",
  "description": "A supplier file arrives with duplicates and mixed formats.",
  "decision": "Validate grain, keys, types and missing identifiers first."
}
```

### Achievement

```json
{
  "id": "first-query",
  "title": "First Query",
  "description": "Complete your first SQL task.",
  "rule": {"type": "skill_attempts", "skillKey": "sql", "minimum": 1}
}
```

## Offline installation sequence

`ContentPackLoader.installBundledPacks()` reads the bundled JSON asset through Flutter's asset bundle and then:

1. decodes JSON,
2. validates root/version/collections,
3. validates IDs, references, hints, rubrics and expected answers,
4. opens SQLite,
5. checks installed pack version,
6. checks cross-pack ID ownership,
7. starts one SQLite transaction,
8. retires previous active rows for that pack,
9. updates/inserts pack metadata and all current rows in place,
10. commits.

Any SQLite exception in steps 8–9 rolls back the complete upgrade.

## Bundled five-task reference pack

`assets/content/content_pack_sample_v1.json` is now schema v2/content version 2 and contains five complete reference tasks:

1. spreadsheet net-revenue formula,
2. SQL completed revenue by region,
3. duplicate/data-quality checks,
4. A/B test interpretation,
5. decision-ready written insight.

It includes four datasets, five rubrics, two manager dialogues, four random events and two achievements. Every task contains business context, a dataset reference, a rubric reference, exactly three hints and an expected answer/result.

## Future task-generation checklist

Every generated schema-v2 task must pass all of these before release:

- globally stable task ID within its owning pack,
- explicit skill/difficulty/company/answer type,
- business context and actionable prompt,
- in-pack dataset reference,
- in-pack rubric reference,
- exactly three progressive hints,
- expected answer/result/selection,
- no unsupported/newer pack schema,
- rubric weights total 100,
- content version increased when replacing an installed pack,
- automated loader test confirms install and retry,
- upgrade test confirms old attempts survive,
- rollback test confirms a failed upgrade leaves the old pack unchanged.

This contract is the required format for later requests such as “generate 25 new tasks for a skill/level.”
