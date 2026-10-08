# DataQuest — Job-ready depth and polish audit (October 2026)

## Intended learner promise
**Learn from zero → Work like an analyst → Prove you can do the job.**
Play Store positioning: **DataQuest — Become a Data Analyst by Doing the Job.**

## Ten requested areas — actual implementation state

| Area | Present | Depth/polish remaining |
| --- | --- | --- |
| Day at Work | Five connected flagship workdays, time-based briefing, dirty-data triage, analysis, statistics, dashboard decision and manager review. Primary Home CTA and sequential stages in this PR. | More realistic documents, exportable complete datasets, interrupts and real-time follow-ups. |
| Independence | Guided Foundation and role progression. Advanced flagship statistics/dashboard decisions require written justifications in this PR. | Less prompted independent SQL/cleaning at Analyst/Head ranks. |
| Five portfolio projects | E-commerce, SaaS, bank, hospital and logistics, with exportable project folders. This PR adds statistics, dashboard plan and transparent limitations. | Full reproducible raw datasets, practitioner review of rubrics and external portfolio evaluation. |
| Smart failure feedback | SQL result grader, task-specific feedback, and this PR's join/grain/denominator and manager-overclaim diagnostics. | Executed counterexamples, true DAX filter-context evaluation and unit-tested causal inference reasoning. |
| Business knowledge | Five domain playbooks and metric definitions. | Expand worked metric formulas and linked multi-period business forecasts. |
| Senior leadership | Senior/Lead/Head leadership decisions and career gating. | Open-ended resource allocation and team review, not only fixed choices. |
| Tool fidelity | SQL executes against local SQLite. Pandas is a simulator; Excel is a workbook simulator; Power BI validates concepts and patterns. | Sandboxed genuine Python; real spreadsheet functions; DAX/Power BI engine integration. Do not claim native runtime fidelity yet. |
| Adaptive manager | Offline question selection and rubric-based manager feedback. | Optional opt-in AI dynamic interview dialogue, privacy controls, scripted offline fallback. |
| Educational QA | Automated content structural and invalid-claim tests; decision-rubric unit tests in this PR. | Expert sign-off covering each discipline before public job-ready claims. |
| 50–100 user beta | Local opens, D1/D7 activity and workday completions; per-stage completion funnel added in this PR. | Actual learner recruitment, usability testing, privacy-consented aggregate analysis and iteration. |

## Workday scoring integrity
The offline open-ended evaluator recognizes required concepts plus complete-sentence explanations. It **does not** execute Excel/Pandas/DAX and cannot judge every valid paraphrase. Wrongly accepted/failed responses should be reviewed and the rubrics versioned. Do not equate high rubric score with demonstrated employment competence.

## Completion criteria before claiming 9.5/10
- A cold-start beginner can finish their first workday without confusion and explain at least one result.
- At least one end-to-end flagship output can be reproduced using the attached complete raw dataset and an actual tool.
- Advanced workdays accept multiple genuinely correct methods, not just prescribed phrasing.
- Expert educational review is signed off across SQL, statistics, business metrics, Excel, Python/Pandas and BI/DAX.
- A documented pilot with 50–100 target learners measures first workday/project completion, Day 1/7 retention, independence and willingness to pay.
- The production CI gate passes and app flows are tested on representative Android devices.

## Validation
Run `flutter analyze` and `flutter test` on each pull request. GitHub Actions additionally produces an APK and AAB. The branch must not be merged if checks fail. Human education, accessibility and usability QA are still required.

## Compatibility
Changes preserve existing stored attempt IDs, SQLite data and SharedPreferences keys; stage telemetry is additive and locally stored. Do not reset user data to apply these changes.
