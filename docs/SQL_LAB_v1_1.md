# DataQuest v1.1 — SQL Lab

Expansion Item 4 completes the offline SQL practice loop.

Learners solve business tickets in an in-app multiline SQL editor with touch shortcuts. The same shortcut catalog is shared with the SQL Workstation and covers filters, joins, grouping, CTEs, CASE and window functions. Every SQL task also links directly to **Schema & scratchpad** so the learner can inspect local table columns and preview rows without losing the task draft.

`SqlRunner` executes one read-only SELECT/CTE against the on-device SQLite learning database and caps displayed results at 100 rows. Mutating/schema commands and multiple statements are rejected. Common table, column, aggregate, window, function, incomplete-input, circular-CTE and syntax errors are translated into plain language.

The result grader accepts equivalent SQL by grading output instead of query text. It validates required output aliases, row count and each column-to-value relationship after normalization. Row order is ignored when the business result is otherwise identical.

The core progression contains exactly 20 SQL tasks: 6 Beginner (SELECT/WHERE, ORDER BY/LIMIT, grouped aggregation), 7 Intermediate (joins, conditional aggregation, HAVING, subquery benchmarks, CTEs, CASE, DISTINCT), and 7 Advanced (ROW_NUMBER, RANK, cumulative SUM, LAG, moving average, window share, PARTITION BY). Every task retains exactly three progressive hints.

`test/sql_lab_curriculum_test.dart` executes all 20 hidden reference solutions against the production seeded SQLite database and grades their results, preventing stale expected output from shipping.
