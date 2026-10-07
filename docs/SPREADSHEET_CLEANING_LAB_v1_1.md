# DataQuest v1.1 — Spreadsheet & Data Cleaning Lab

Expansion Item 5 completes the offline, touch-first workbook simulator.

## Workbook workflows

The lab supports:
- spreadsheet formulas with normalized cell-reference grading,
- exact key lookups,
- ascending/descending sorting,
- equality filters,
- pivot SUM and COUNT summaries,
- null/blank filling,
- duplicate removal by documented business key,
- text-label normalization,
- non-negative domain validation,
- date normalization to YYYY-MM-DD,
- IQR-based statistical outlier exclusion.

The simulator does not mutate a real external workbook. It executes safe deterministic workbook commands against the task's local rows and auto-grades the resulting table.

## Touch interaction

Every task exposes horizontal shortcut chips. A collapsible **Workbook action syntax** panel provides tappable command templates for formula, lookup, sort, filter, pivot and cleaning actions. Tables remain horizontally swipeable for narrow Android screens.

## Validation and grading

Commands now validate:
- requested columns exist,
- sort direction is ASC or DESC,
- pivot aggregation is supported,
- numeric actions receive numeric values,
- IQR cleaning has enough numeric observations,
- date values can be parsed.

Lookups and filters match text case-insensitively while returning original source values.

Formula tasks normalize whitespace, case and absolute-reference markers. Row-producing tasks are graded using the shared structural result grader; sort tasks additionally enforce requested row order.

## Outlier rule

`CLEAN OUTLIERS_IQR <column>` calculates Q1 and Q3 using linear percentile interpolation and removes values outside:

`Q1 - 1.5 × IQR` to `Q3 + 1.5 × IQR`.

Missing values are left untouched because missing-value treatment is a separate analytical decision. At least four numeric observations are required.

## Content inventory

The existing 15 shipped tasks are preserved with stable IDs:
- 10 spreadsheet tasks: 2 formulas, 2 lookups, 2 sorts, 2 filters and 2 pivots.
- 5 cleaning tasks: missing values, duplicates, categorical format normalization, domain-invalid negative values and mixed date formats.

Outlier handling is added as a simulator capability without changing those stable task identities or historical player evidence.

## CI verification

`test/spreadsheet_lab_curriculum_test.dart` loads all 15 shipped challenges from assets and executes each challenge's expected command through the production simulator. The test also checks the required workflow coverage and three-level hints.

`test/spreadsheet_simulator_test.dart` covers formula normalization, order-sensitive sorting, case-insensitive lookup/filter behavior, pivoting, date normalization, IQR outlier removal and clear invalid-column/direction errors.
