# DataQuest vNext — implemented workstreams and honest release gates

Last reviewed: 2026-10-08. Branch: `feature/full-quality-workstreams-20261008`.
This branch inherits the features of `feature/assessment-trust-and-autosave-20261008`. The parent PR #4 and predecessor PRs #1/#2 are not merged to main; avoid duplicate merges.

## Delivered in GitHub source (requires final CI and device validation)
1. **Saved workday drafts**: the prior assessment branch autosaves unfinished choices, analyst code, statistics, dashboard and manager text with a local persistence queue.
2. **SQL grading**: real SQLite workbench; refusal to grade incomplete/truncated 100-row previews; case-specific changed-data holdout queries run inside rolled-back transactions to reject hardcoded or memorized example values.
3. **Five company replayability**: e-commerce full versioned source remains available. SaaS, bank, hospital and logistics now export their complete synthetic SQLite source tables to CSV, standalone dataset.sql and reference SQL. Evidence metadata distinguishes example matching, changed-data matching, synthetic data and external review.
4. **Workbook arithmetic**: +, -, *, /, parentheses, cell references, simple SUM/AVERAGE/MIN/MAX; formula evaluation on actual and changed row values rather than comparing formula strings. It is NOT Excel and does not implement all spreadsheet formulas, lookup semantics or an editable grid.
5. **Business decision after-effects**: scoring and the learner's manager recommendation create a deterministic, persistent four-day simulation. The resulting synthetic daily data can be queried from SQLite table `dq_company_followup_daily`; a UI card distinguishes costs, KPI changes and external disruption. This is a scripted educational model, NOT evidence of causal real-world business results.
6. **Provenance**: a `changedDataPassed` field is saved with flagship attempts; no zero-hint or recruiter endorsement is implied by passing a single holdout.

## NOT yet delivered — cannot honestly claim these are finished
- Genuine in-app CPython/Pandas execution: current Pandas engine remains a guided pattern simulator. Android sandbox/runtime, package size, low-end RAM, isolation and user-data privacy require a separate implementation and threat review. Do NOT quietly run untrusted Python using a host shell.
- Full Microsoft Excel or Power BI compatibility: formulas supported above are intentionally limited; the current BI exercises do not execute the Power BI engine or arbitrary DAX.
- Dynamic AI-led manager chats, complex company financial models with audited coefficients, fully open-ended employee performance reviews, and realistic causal attribution.
- External domain-expert validation of statistics/BI/business finance and graded project solutions.
- Android manual testing including 2 GB RAM, TalkBack, font scaling, forced-stop recovery and offline install.
- Controlled cohort study with 50–100 learners, D1/D7 retention, comparative learning gain and verified willingness-to-pay. No such real user results are available in GitHub, and simulator reactions are not substitutes.
- Real recruiter/hiring-manager validation or actual employment outcomes.
- Brand/trademark due diligence for the name DataQuest.

## Remaining acceptance tests / practical completion path
- Run Flutter analyzer, all automated tests and full Android release builds on the **exact final commit**. Only merge after green checks.
- For each complete synthetic SQL portfolio, replay dataset.sql and reference_query.sql in a fresh local SQLite database. Compare results and record external replay, version/date and reviewer.
- Trial 3 reference workbook formulas plus 5 distinct equivalent formulas and wrong-value expressions on mutated data. Inspect errors on low-end Android.
- Add a **sandboxed Python backend/runtime** in a separate PR before claiming actual Python/Pandas execution. Explicitly design an offline practice fallback.
- Extend spreadsheet support to actual cell editing, conditional functions and lookups, then evaluate alternative valid formulas.
- Improve DAX semantic modeling with relationship/filter-context tests in a separate PR, or explicit desktop Power BI exports.
- Validate decisions' follow-up numbers with business domain reviewers. Where consequences are synthetic assumptions, keep the synthetic indicator visible.
- Recruit a consented 50–100-user beta; observe first-workday completion, hint-free unseen task accuracy and D1/D7 activity, and interview recruiters.

## Claim restrictions
Do not present in-game graduation as an accredited qualification. Do not present modeled outcomes as actual company results. Do not present internal Job Readiness score as validated employment or hiring probability. Do not say that all requested improvements are complete simply because the branch compiles.
