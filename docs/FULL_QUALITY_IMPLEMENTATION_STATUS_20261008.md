# DataQuest — Implementation and validation ledger (2026-10-08)

Branch: feature/full-jobready-next-wave-20261008
Parent: feature/assessment-trust-and-autosave-20261008 (which includes PR #2)
This work intentionally does not merge or modify main.

## What has been implemented in code

| Objective | Actual implementation | Evidence and limitations |
| --- | --- | --- |
| Correct SQL assessment | Execute SQLite, reject truncated results, reject literal table-name games, repeat the flagship query on changed data inside a rolled-back transaction | Five flagship case SQL paths; no general proof of SQL equivalence |
| Durable drafts | Debounced local saves, lifecycle flush, per-workday persistence write queue | Needs real-device kill/resume testing; recovery is not transactional across all Android failure types |
| Real spreadsheet calculations | In-app arithmetic/cell/range evaluator; SUM, AVERAGE, MIN, MAX, COUNT; grade equivalence on altered inputs | Not an Excel workbook, not Excel formula completeness, macros unsupported |
| SaaS / bank / hospital / logistics raw projects | Four complete versioned synthetic event datasets, deduplicated clean-view SQL, expected result arrays, full event export and SQLite replay | Small synthetic fixtures; independent expert check is still required |
| E-commerce end-to-end project | Previous SQL reproducibility v2, full event data, CSV/ZIP, changed-data check | Single-period synthetic data, not real employer results |
| Genuine Python/Pandas | Optional localhost Docker companion executes Pandas for bundled synthetic rows; requires explicit button click; worker isolated and resource-limited | Not native Android Python, not broadly security-audited, no verified unseen-Python graduation gate; current Android mode retains simulator |
| Power BI concepts | Actual in-app calculations for a restricted DAX-like SUM/CALCULATE/ALL customer-sales filter context subset, with slicer comparisons | Not Microsoft Power BI or full DAX execution |
| Business consequences | A saved day-two intervention screen with budget/service/cost/risk trade-offs and an exogenous shock; outcome included in portfolio export | First version is a deterministic outcome model, not a persistent economy with generated subsequent SQL datasets |
| Independent practical exam | New no-hint SQL challenge with unfamiliar event schema, actual SQLite and altered-data verification, local pass record; linked in Job Readiness | Training-specific exam only; no employer accreditation; graduation gates unchanged for existing users |
| Beta measurement and privacy | Existing local funnel + new explicit-consent aggregate export with no raw free text, dates or identifier fields | No real 50–100 learner cohort, retention measurement across people, expert reviewer sign-off, physical-device QA or market study has been conducted |

## Honest product positioning

- The app is a synthetic/offline-first career practice game with increasingly realistic executable exercises.
- A DataQuest score is **not** a prediction of actual employment success.
- A portfolio must disclose synthetic cases, human assistance, hints, tool limits, and exact reproducible code.
- The genuine-Pandas companion works only in separately configured local Docker; do not imply it runs as native Python on every Android phone.
- The DAX subset demonstrates filter semantics but is not equivalent to the proprietary Power BI engine.
- A model-generated or scripted company outcome is not empirical evidence of causation.

## Tests available
- flutter analyze
- flutter test (including formula equivalence; five company SQL cases; changed-data rollback; BI filter context; next-day persistence; independent unseen SQL practical; privacy-minimized beta summary)
- Flutter debug APK, release AAB, split release APK and release budgets in GitHub Actions
- Genuine Pandas Companion Checks (real Pandas worker execution plus required Docker flags)
- Manual device tests still required on real Android 2 GB / 4 GB, interrupted sessions, airplane mode, keyboard visibility, font scaling and TalkBack

## Remaining release gates — cannot be implemented away

1. **Genuine Android Python/DAX parity:** full native Python and Microsoft Power BI execution are not bundled. Keep partial tools explicitly labeled or provide verified integrations without breaking offline guarantees.
2. **Realistic extended business economy:** next-day consequences are saved and bounded, but truly dynamic data-driven multi-week companies and budget continuity remain further engineering.
3. **Expert independent review:** practitioner checks covering metrics, causality, statistics, SQL, Python, Excel and BI are still needed.
4. **Human beta:** recruit 50–100 consenting learners, run moderated tests and calculate authentic project completion, D1/D7 retention, unseen-skill success and willingness to pay. Never replace that evidence with imagined results.
5. **Brand and distribution due diligence:** name availability, Play Store presentation, accessibility, real phone smoke tests and security review.
6. **Production merge:** only after passing CI on exact branch head. Existing PRs remain isolated until deliberately reconciled.

Full roadmap: docs/DATAQUEST_QUALITY_ROADMAP_20261008.md
