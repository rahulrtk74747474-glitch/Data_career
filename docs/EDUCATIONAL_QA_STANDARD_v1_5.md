# DataQuest v1.5 Educational QA Standard

DataQuest must not call a learner "job-ready" merely because they collected XP. Educational content is treated as product-critical logic.

## Automated gates

CI verifies that trusted teaching fields do not contain known-invalid claims such as:
- correlation proves causation;
- a p-value is the probability that the null hypothesis is true;
- p > 0.05 proves there is no effect;
- every outlier is an error and should be deleted;
- NRR above 100% means there was no churn.

Distractor answers may intentionally contain incorrect claims, so automated scanning is restricted to trusted fields: explanations, solutions, correct/reference answers and manager model responses.

The v1.5 flagship pack must also satisfy structural gates:
- exactly five company flagship workdays;
- one project per company;
- data-quality traps and at least three correct controls per workday;
- all four tool choices represented;
- non-empty statistical reference, manager reference and resume evidence;
- uncertainty and recommendation language in manager-ready references.

## Tool-fidelity disclosure

- SQL runs against local SQLite and is actually executed.
- Pandas exercises validate Pandas-style expressions and simulate results; the app does not bundle CPython.
- Excel exercises use an in-app workbook simulator; they are not Microsoft Excel.
- Power BI exercises validate BI/DAX/modeling decisions; the app does not bundle the Microsoft Power BI engine.

The UI and store listing must not imply otherwise.

## Human review gate before production marketing

Automated tests cannot replace domain review. Before a production claim such as "complete job-ready curriculum", sample content from Statistics, SQL, Excel, Pandas, Power BI and business/finance should be reviewed by experienced practitioners. Findings should be versioned and corrected before broad paid acquisition.

## Evidence standard

Job readiness should emphasize independent/open-ended project performance, retained mastery, communication quality, interview performance and portfolio breadth—not raw XP or streak alone.
