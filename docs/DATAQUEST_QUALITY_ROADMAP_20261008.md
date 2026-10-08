# DataQuest — quality, fidelity and launch roadmap
**Review date:** 2026-10-08
**Branch:** `feature/assessment-trust-and-autosave-20261008`
**Status:** Phase 1 underway; further work below is NOT shipped. No market/learning claims without real pilot evidence.

## Verified strengths before this branch
- Offline-first Flutter learning and career system, SQL backed by SQLite.
- Five company flagship workdays with structured stages and portfolio framing.
- E-commerce case v2 has complete event datasets and reproducible export ZIP.
- Prior feature branch CI #414 passed automated analysis/tests and Android builds.

## Phase 1 — defensible assessment and recovery [Implemented in this PR; CI required]
- Grade real SQL execution and explicitly fail truncated 100-row previews in assessed paths.
- Reject queries that merely mention required case tables in comments/literals.
- Recheck e-commerce SQL on changed data inside a transaction that always rolls back.
- Expose separate base-result, changed-data and verified flags in exported project evidence.
- Persist unfinished workday quality selections, tool, analysis, reasoning, chart and manager answer with debounce and lifecycle flush.
- Serialize concurrent workday persistence updates and test read-after-write.
- Block unqualified causal certainty in advanced reasoning rubrics.
- Limitations: only e-commerce has a perturbed-data regression check; offline prose scoring remains heuristic; automated save is not crash-proof without device testing.

**Acceptance:** `flutter analyze`; `flutter test`; Android APK + AAB build; manual test airplane mode, forced stop, resume, accessibility and keyboard visibility. All original save formats remain backward-compatible.

## Phase 2 — true executable tools [NOT IMPLEMENTED]
1. **Python:** Choose a maintainable, isolated code execution approach. If local Android, test ARM32/ARM64 performance and RAM impact (2 GB devices). If remote, require explicit user opt-in, do not upload learner data silently, and always offer offline guided fallback. Implement actual `pandas` dataframe execution against tests with hidden inputs; cap CPU/time/memory, filesystem and network, and instrument user-visible errors.
2. **Spreadsheet:** Replace formula string matching with cell formula parsing and evaluation; grid navigation, references, operators, SUM/AVERAGE/IF/COUNTIF/SUMIFS/LOOKUP, sort/filter, pivot tables, missing-value handling, and XLSX/CSV exchange where feasible. Grade workbook *results*, including alternative correct formulas.
3. **BI:** An accurate in-app star schema/relationships/filter-context engine and DAX-like measured exercises OR export project materials for evaluation in external Power BI. Explicitly label conceptual exercises as conceptual, not genuine Power BI runs.
4. Keep executable environments opt-in, secure and tested. Do not claim Microsoft compatibility if not demonstrated.

**Acceptance:** distinct valid solutions to the same task pass; syntactically plausible wrong solutions fail; no implementation-level answer fragments in the grader. Gold reference outputs on randomized/unseen datasets plus negative tests.

## Phase 3 — five fully reproducible workplace cases [NOT IMPLEMENTED]
- Provide complete raw event/source tables, data dictionary, source data quality traps, business logic, checked solutions, portable SQL/scripts, output CSV and replay README for SaaS, bank, hospital and logistics.
- Include duplicates, late arriving changes, type errors, conflicting denominators, and alternative valid analytical methods.
- Require independent expert sign-off for causal inference, business metrics, currency, privacy and domain-specific sensitivity.
- Include explicit uncertainty, how assumptions affect results, and whether a proposed KPI improvement actually benefits customers.
- Mark assisted versus hint-free independent attempts separately in portfolio.
- Keep trainer-provided reference solutions out of user-produced `submitted_query.sql` evidence.

**Acceptance:** an external analyst reproduces each project's results from its raw files on a separate machine, with code and outputs linked to their provenance.

## Phase 4 — genuinely persistent company consequences [NOT IMPLEMENTED]
- Use seeded, versioned state-transition logic: a recommendation affects future operating variables and datasets but may also have tradeoffs.
- Introduce next-day incidents, new manager requests, budget/resource constraints and delayed outcome measurement.
- Show counterfactuals when permitted and prevent the game from attributing all changes to the learner's decision.
- Test transitions deterministically from chosen decision + initial state; reject impossible metrics (negative costs, occupancy > physical capacity).
- Include manager scrutiny when the learner overclaims causality or acts on incomplete data.

**Acceptance:** two meaningfully different decisions lead to explainable, testable downstream changes on a later workday, without corrupting earlier progress or certificates.

## Phase 5 — trustworthy career proof [NOT IMPLEMENTED]
- Separate badges for `Concept practiced`, `Guided project`, `Independent unseen assessment` and `Reproduced portfolio`.
- Require a hint-free project on unseen dataset plus an oral/written business explanation before higher-level graduation claims.
- Recruiter view exports scripts, methodology and limitations with explicit disclosure of synthetic employer/project.
- Job matching is an internal learning-gap estimate; do not call it a predictor of interview offers or hiring.

**Acceptance:** expert raters blinded to the learner's in-app score can review and reproduce artifacts and evaluate unseen solutions.

## Phase 6 — usability, beta and brand gate [NOT IMPLEMENTED]
- Conduct device tests on several Android versions, 2 GB/4 GB memory, small displays, TalkBack, font scaling, keyboard, process termination and airplane mode.
- Conduct 10 moderated user tests, fix severe first-day confusion, then 50–100 opt-in learner beta including beginners and career switchers.
- Define acquisition cohort denominators, first day completion, D1/D7 retention, hints used, unseen assessment success, customer support and willingness to pay.
- Compare outcomes in a real randomized pilot where possible. Report confidence/uncertainty and do not translate hypothetical simulation into product demand.
- Resolve the DataQuest name-confusion/trademark risk before commercial promotion.
- Do not promise employment, a degree or accreditation.

**Acceptance:** complete release QA and evidence that learners can learn independently without expensive support.

## Priorities and guardrails
P0 = correct grading, durable progress, actual data use, transparent assessment.
P1 = real Python/spreadsheet/BI evaluation and complete cases.
P2 = connected choices, employer-quality portfolio and engaging narrative.
P3 = paid acquisition, monetization and optional social/cloud features.

No feature counts or internal readiness percentages should substitute for independent analyst competence, authentic research, accessible UX and real user retention.
