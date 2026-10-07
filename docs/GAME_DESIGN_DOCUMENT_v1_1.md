# DataQuest: Analyst Career — Game Design Document v1.1

Status: **Expansion Item 1 — Design baseline**
Base application: **DataQuest v1.0.0+10**
Verified baseline: Phase 1–10 complete, 107 tests, Android APK/AAB release artifacts verified.

---

# 1. Product vision

**DataQuest: Analyst Career** is an offline-first career simulation and learning game that teaches practical data-analysis work by placing the player inside increasingly complex companies.

The player does not learn analytics as disconnected textbook chapters. They receive realistic company tickets, inspect messy data, choose tools, make mistakes safely, use progressive hints, explain findings to managers, and see business consequences.

The core loop is:

**Learn → Try → Fail safely → Hint → Explanation → Retry → Apply → Review → Advance**

The game should make the player capable of:
- writing practical SQL;
- working with spreadsheets;
- cleaning messy business data;
- reasoning with statistics;
- using guided Python/Pandas workflows;
- selecting KPIs and charts;
- understanding funnels, cohorts, retention, CAC, LTV and forecasts;
- writing clear, evidence-backed business insights;
- communicating uncertainty;
- handling privacy and professional-ethics situations;
- completing analyst interviews and portfolio-ready cases.

The product is Android-first, optimized for low-end devices and fully usable without internet.

---

# 2. Player fantasy and story

The player begins as a new analyst with no authority and limited access. Early work is tactical: correcting spreadsheets, checking exports and answering simple questions.

As performance improves, the player earns trust, receives more ambiguous requests and gains access to more complex companies. By the end of the game, the player is not only writing queries; they are deciding what should be measured, challenging weak executive conclusions, designing analytical work, and explaining trade-offs.

The player journey is deliberately career-shaped rather than level-shaped:

1. **Intern** — learns mechanics and data hygiene.
2. **Junior Analyst** — answers defined business questions.
3. **Data Analyst** — owns recurring reporting and cross-team analysis.
4. **Senior Analyst** — diagnoses ambiguous problems and designs analysis.
5. **Lead Analyst** — reviews others' work, defines metrics and manages risk.
6. **Head of Analytics** — communicates to executives, sets analytical standards and leads cross-company decisions.

The player's company journey is separately tracked so career title and industry experience are independent.

---

# 3. Company timeline

## Company 1 — E-commerce Co.

**Career focus:** foundations.

Departments:
- Sales
- Marketing
- Operations
- Finance
- Customer Experience
- CEO

Primary skills:
- spreadsheets;
- SQL basics;
- cleaning;
- descriptive statistics;
- conversion/revenue KPIs;
- clear insight writing.

Business questions:
- Which marketing channel converts?
- What is net revenue?
- Which customer segment generates revenue?
- Are duplicates or missing fields corrupting the report?
- Is an apparent correlation meaningful?

Key simulated company metrics:
- revenue index;
- churn/return proxy;
- cost index;
- customer satisfaction.

## Company 2 — SaaS Growth Co.

**Career focus:** retention and recurring revenue.

Primary skills:
- active-customer definitions;
- MRR/ARR concepts;
- logo retention;
- NRR;
- cohorts;
- experiments;
- funnel leakage;
- segment comparisons.

Business questions:
- Which segment has better retention?
- How should active MRR be defined?
- Is the experiment conclusive?
- What drives NRR?

## Company 3 — NorthStar Bank Analytics

**Career focus:** governance, risk signals and careful interpretation.

Primary skills:
- advanced SQL;
- portfolio aggregation;
- operational review queues;
- risk-band analysis;
- anomaly/review signals;
- governance and fairness.

Business rules:
- review flags are prioritization signals, not proof of fraud;
- exercises avoid automatic adverse individual decisions;
- all banking data is synthetic.

## Company 4 — Harborview Hospital Analytics

**Career focus:** operational analytics under higher consequence.

Primary skills:
- wait-time analysis;
- capacity utilization;
- demand forecasting;
- operations cohorts;
- data-quality validation;
- executive communication.

Safety boundary:
- operational analytics only;
- no real PHI;
- no diagnosis;
- no treatment recommendations;
- no clinical decision support.

## Company 5 — Logistics Network Co.

**Career focus:** network optimization and executive analytics.

Primary skills:
- SLA analysis;
- route comparisons;
- throughput forecasting;
- warehouse utilization;
- normalized cost;
- delay-driver analysis;
- operational recommendations.

Final company review leads into:
- cross-company capstone;
- Interview Gauntlet;
- Job Readiness Score;
- graduation/certificate.

---

# 4. Career level map

| Level | Role | Core expectation | Typical difficulty | Authority |
|---|---|---|---|---|
| 0 | Intern | Follow defined steps; basic formulas/filters | Beginner | None |
| 1 | Junior Analyst | Answer scoped questions independently | Beginner → Intermediate | Low |
| 2 | Data Analyst | Own recurring analysis and definitions | Intermediate | Medium |
| 3 | Senior Analyst | Diagnose ambiguous problems | Intermediate → Advanced | Medium-high |
| 4 | Lead Analyst | Review logic, metrics and risk | Advanced | High |
| 5 | Head of Analytics | Set analytical direction and communicate to executives | Advanced / Boss | Executive |

Promotion is evidence-gated. XP can make a player eligible, but evidence quality should determine promotion.

Recommended promotion signals:
- minimum XP;
- minimum completed company tickets;
- minimum average attempted-skill mastery;
- Boss Case threshold;
- interview threshold at later levels;
- company chapter review where applicable.

---

# 5. Learning systems

## 5.1 Three-level hints

Every substantial task supports three hint levels:

**Hint 1 — Direction**
- reminds the learner what concept matters;
- never reveals the answer.

**Hint 2 — Structure**
- identifies the formula/query pattern or analytical structure.

**Hint 3 — Near-solution**
- gives a concrete pattern or worked fragment;
- still requires the player to complete/submit.

Using hints reduces score but never blocks completion.

## 5.2 Failure philosophy

Wrong answers should:
- explain why the answer failed;
- identify the concept to revisit;
- preserve the player's attempt;
- allow immediate retry;
- avoid punitive loss of career progress.

## 5.3 Spaced review

Weak and due concepts re-enter the Review Queue.

Recommended review intervals:
- first successful exposure: +1 day;
- second: +3 days;
- third: +7 days;
- later strong performance: +14–30 days.

---

# 6. Scoring system

## 6.1 Standard ticket score

Recommended unified score:

`Base = 100`

Penalties:
- Hint 1: −10
- Hint 2: additional −10
- Hint 3: additional −15
- Incorrect submission: −8 each, capped at −32
- Required-data-quality omission: −10 where applicable

Minimum completion score after eventual correct solution:
- **40/100**

Score bands:
- 90–100: Excellent
- 80–89: Strong
- 70–79: Competent
- 60–69: Developing
- 40–59: Needs review
- <40: not considered passed for gated content

Existing DataQuest modes may use specialized rubrics, but v1.1 should normalize displayed results to a 0–100 scale.

## 6.2 Boss Case / Capstone scoring

Boss Cases use weighted components.

Recommended general rubric:
- Cleaning / validation: 15–20%
- SQL / transformation: 25–30%
- Statistics / KPI reasoning: 15–20%
- Visualization / dashboard choice: 10%
- Recommendation / communication: 20%

Final capstone:
- Cleaning: 15
- SQL: 25
- Statistics: 15
- KPI: 15
- Dashboard: 10
- Executive recommendation: 20
- Total: 100

## 6.3 Insight-writing rubric

Each written insight is graded across four dimensions:

| Dimension | Weight | Strong answer |
|---|---:|---|
| Clarity | 25 | concise, understandable, no unnecessary jargon |
| Evidence | 30 | cites the relevant metric/data |
| Recommendation | 25 | proposes a bounded next action |
| Business impact | 20 | explains why the action matters |

Total: 100.

Suggested pass mark: 70.

## 6.4 Interview scoring

- objective SQL/choice questions: 100 or 0, averaged;
- rubric questions: weighted criteria;
- timed-mode completion records elapsed/timeout state;
- best and latest scores stored separately.

Graduation target:
- Interview Gauntlet ≥75.

## 6.5 Mastery update

Recommended mastery model:

`new_mastery = old_mastery × 0.75 + normalized_attempt_score × 0.25`

For first attempt:
`new_mastery = normalized_attempt_score`

Additional modifiers may be used for spaced-review success, but mastery must stay in [0,100].

---

# 7. XP and progression economy

Suggested XP by difficulty:

- Beginner: 60–90 XP
- Intermediate: 100–150 XP
- Advanced: 160–230 XP
- Boss Case: 250–400 XP
- Final capstone: 500 XP first completion only

XP rewards progression but **must not directly equal job readiness**.

Recommended career eligibility thresholds:

| Role | Suggested XP floor |
|---|---:|
| Intern | 0 |
| Junior | 200 |
| Data Analyst | 500 |
| Senior | 900 |
| Lead | 1400 |
| Head of Analytics | 2000 |

Evidence gates remain required even when the XP floor is met.

---

# 8. Company-growth formulas

The company simulation should use normalized indexes so content can work across industries.

Initial baseline:
- Revenue Index = 100
- Cost Index = 100
- Satisfaction = 70
- Churn/Exception Rate = industry-specific baseline

## 8.1 Revenue index

For each decision/task impact:

`Revenue_next = Revenue_current × (1 + revenue_effect_pct / 100)`

Example:
- Revenue Index 100
- correct campaign recommendation +2%
- new Revenue Index = 102

Clamp recommended range:
`50 ≤ Revenue Index ≤ 250`

## 8.2 Cost index

`Cost_next = Cost_current × (1 + cost_effect_pct / 100)`

Lower cost is not automatically good; recommendations can trade cost for service.

Clamp:
`50 ≤ Cost Index ≤ 250`

## 8.3 Churn / exception rate

For SaaS/e-commerce churn-like metrics:

`Churn_next = clamp(Churn_current + churn_delta_pp, 0, 100)`

For bank/hospital/logistics, the same engine can represent:
- exception rate;
- cancellation rate;
- delay rate;
- review rate;

while preserving the company-specific label.

## 8.4 Satisfaction

`Satisfaction_next = clamp(Satisfaction_current + satisfaction_delta, 0, 100)`

## 8.5 Composite company health

Recommended executive summary metric:

`Health = 0.35 × RevenueScore + 0.25 × Satisfaction + 0.20 × CostEfficiency + 0.20 × RiskControl`

Where:
- `RevenueScore = clamp(RevenueIndex, 0, 100)` for display normalization;
- `CostEfficiency = clamp(200 - CostIndex, 0, 100)`;
- `RiskControl = 100 - churn_or_exception_rate`.

This health score is descriptive game feedback only. It should not replace individual KPIs.

## 8.6 Decision impact strength

To prevent one task from unrealistically changing the company:

- routine ticket: ±0.5% to ±2%
- advanced recommendation: ±1% to ±3%
- Boss Case: ±2% to ±5%
- random event: temporary ±1% to ±4%

---

# 9. Random-event design

Events interrupt normal work and teach ambiguity.

Required v1.1 event categories:

1. **Dirty vendor data**
   - duplicate IDs;
   - changed date format;
   - missing category mapping.

2. **Urgent CEO request**
   - executive asks for a number immediately;
   - player chooses speed vs validation;
   - strongest response gives preliminary result with limitations.

3. **Conflicting reports**
   - Finance and Sales show different revenue;
   - player traces definitions/time windows/refunds.

4. **Privacy incident**
   - sensitive field appears in an export;
   - player must minimize access, stop unsafe sharing and escalate appropriately.

5. **Metric-definition conflict**
   - two teams use different active-user definitions.

6. **Late source-system refresh**
   - dashboard data is incomplete.

Events should affect:
- company metric indexes;
- professionalism/ethics mastery;
- manager trust;
- monthly review notes.

---

# 10. Monthly performance review

Every four in-game weeks:

Review inputs:
- average ticket score;
- mastery trend;
- hints used;
- rework rate;
- Boss Case score;
- insight-writing score;
- professionalism event outcomes;
- streak/review consistency.

Review output:
- strongest skill;
- weakest skill;
- manager narrative;
- promotion readiness;
- 1–3 specific development goals.

Suggested overall review score:

`Review = 0.35 × TaskQuality + 0.20 × Mastery + 0.15 × BusinessCommunication + 0.10 × Professionalism + 0.10 × ReviewConsistency + 0.10 × BossCase`

---

# 11. Current task inventory in verified v1.0

The following are the current primary Career/Pandas/Dashboard learning tasks discovered in checked-in content.

## 11.1 Spreadsheets

- Fix the Sales Revenue Sheet — Beginner/foundation

Current primary count: **1**

## 11.2 SQL

- Which Marketing Channel Converts? — Beginner/foundation
- Revenue by Customer Segment — Intermediate
- Large Orders by Status — Intermediate
- Calculate Active MRR by Segment — Intermediate
- Aggregate Credit Exposure by Risk Band — Advanced
- Find Review Workload by Channel — Advanced
- Compare Average Wait Time by Unit — Advanced
- Find Forecast Capacity Gaps — Advanced
- Measure Route SLA Performance — Advanced
- Find Network Throughput Gaps — Advanced
- Find Peak Warehouse Utilization — Advanced
- Compare Route Cost per Kilogram — Advanced

Current primary count: **12**

## 11.3 Data cleaning

- Clean the Broken Customer Export — Beginner/foundation
- Handle a Suspicious Outlier — Intermediate
- Validate the Operations Extract — Advanced
- Validate the Shipment Extract — Advanced

Current primary count: **4**

## 11.4 Statistics

- Stop a Bad Executive Conclusion — Beginner/foundation
- Choose a Robust Typical Order Value — Beginner
- Interpret an Inconclusive A/B Test — Advanced
- Interpret a Retention Experiment — Intermediate
- Challenge a Credit Policy Shortcut — Advanced
- Interpret an Average Wait-Time Increase — Advanced
- Interpret a Route SLA Difference — Advanced

Current primary count: **7**

## 11.5 Python/Pandas

Career concept:
- Recognize the Pandas GroupBy Pattern — Beginner

Dedicated guided Pandas Lab:
- Filter Completed Orders — Beginner
- Repair Missing Regions — Beginner
- Revenue by Segment — Intermediate
- Find the Top Two Orders — Intermediate
- Create Conversion Rate — Advanced
- Completed Revenue by Region — Advanced

Current dedicated + career count: **7**

## 11.6 Business analytics / metrics

- Fix a Conversion Rate Denominator — Intermediate
- Build a Revenue Metric Tree — Advanced
- Define Monthly Logo Retention — Intermediate
- Choose a Net Revenue Retention Design — Advanced
- Interpret Transaction Review Flags — Advanced
- Choose a Demand Forecasting Approach — Advanced
- Design an Operational Cohort Comparison — Advanced
- Write the Operations Executive Message — Advanced
- Design a Fair Route Cohort — Advanced
- Write the Network Executive Message — Advanced
- Investigate Delay Drivers — Advanced
- Forecast Network Throughput — Advanced

Current primary count: **12**

## 11.7 Dashboard / KPI decision lab

- Show a 12-Month Revenue Trend — Beginner
- Define the Retention KPI — Intermediate
- Catch a Misleading Bar Chart — Intermediate
- Design the Executive Landing Page — Advanced
- Choose the Checkout KPI Set — Advanced

Current dedicated count: **5**

Current primary inventory represented above:
- Career tasks: **37**
- Guided Pandas tasks: **6**
- Dashboard/KPI challenges: **5**
- Total primary learning items: **48**

Interview questions, Daily Challenge wrappers, Boss Cases and the final capstone are additional content and are intentionally not double-counted as standalone core tasks.

---

# 12. MVP v1.1 content target

The expanded MVP should contain **140 core learning tasks**, plus interviews, random events and Boss Cases.

| Skill family | Beginner | Intermediate | Advanced | Total |
|---|---:|---:|---:|---:|
| SQL | 8 | 9 | 8 | **25** |
| Spreadsheets | 6 | 6 | 3 | **15** |
| Data Cleaning | 5 | 6 | 4 | **15** |
| Statistics | 5 | 6 | 4 | **15** |
| Python/Pandas | 5 | 6 | 4 | **15** |
| Dashboards & KPI Design | 5 | 6 | 4 | **15** |
| Business Analytics | 5 | 9 | 6 | **20** |
| Insight Writing / Communication | 3 | 4 | 3 | **10** |
| Professionalism / Ethics | 4 | 3 | 3 | **10** |
| **Total** | **46** | **55** | **39** | **140** |

Additional non-core content:
- 20–30 interview questions/round prompts;
- 10–15 random events;
- 5 company Boss Cases;
- 1 final cross-company capstone;
- 1 Interview Gauntlet;
- rotating Daily Challenges;
- rotating Weekly Cases.

## 12.1 Why 140 tasks

140 is large enough to:
- prevent memorizing only one example per concept;
- support adaptive weak-topic targeting;
- create real Beginner → Intermediate → Advanced progression;
- distribute scenarios across all five industries;
- supply Daily/Review modes without immediate repetition.

It is still small enough for offline JSON content and low-end devices.

---

# 13. Proposed task distribution by company

Core 140 tasks should be reused across modes but authored with industry context.

Recommended split:

| Company / context | Approx. core tasks |
|---|---:|
| E-commerce foundations | 35 |
| SaaS | 25 |
| Banking | 25 |
| Hospital operations | 25 |
| Logistics | 25 |
| Cross-company / general professional | 5 |
| **Total** | **140** |

Tasks should become more ambiguous as companies advance rather than merely using harder syntax.

---

# 14. Skill progression maps

## SQL progression

Beginner:
- SELECT / FROM
- WHERE
- ORDER BY
- LIMIT
- aliases
- basic aggregate
- GROUP BY
- simple CASE

Intermediate:
- joins
- conditional aggregation
- HAVING
- subqueries
- CTEs
- date grouping
- null handling
- multi-column grouping
- business denominator logic

Advanced:
- window functions
- ROW_NUMBER/RANK
- LAG/LEAD
- running totals
- cohort SQL
- retention SQL
- complex CTE chains
- performance/logic review

## Spreadsheet progression

Beginner:
- SUM/AVERAGE
- relative vs absolute references
- IF
- basic sorting/filtering
- date/number formats

Intermediate:
- SUMIFS/COUNTIFS
- XLOOKUP/VLOOKUP concepts
- INDEX/MATCH concept
- nested IF
- text cleanup
- conditional logic
- multi-column sorting/filtering
- simple pivots

Advanced:
- multi-condition lookup
- error-safe formulas
- dynamic KPI sheet design
- pivot-derived executive summary

## Cleaning progression

- null handling
- duplicate detection
- type validation
- date normalization
- categorical standardization
- invalid ranges
- outlier investigation
- grain/uniqueness
- source reconciliation
- audit trail and documented assumptions

## Statistics progression

- mean/median/mode
- variance/std deviation concepts
- distributions
- robust statistics
- sampling
- confidence intervals
- correlation
- A/B testing
- hypothesis tests
- effect size
- power
- multiple-comparison awareness
- causation limits

## Pandas progression

- filtering
- selecting columns
- fillna
- astype concepts
- drop_duplicates
- groupby/agg
- sort_values/head
- merge
- derived columns
- datetime operations
- pivot_table
- transform
- window-like operations
- cohort manipulation

## Business Analytics progression

- revenue
- margin
- conversion
- funnel
- retention
- cohort
- CAC
- LTV
- NRR
- capacity
- SLA
- cost normalization
- forecast
- metric trees
- scenario analysis
- executive recommendation

---

# 15. Boss Case map

## E-commerce Boss Case
Goal: revenue and customer-segment review.

Skills:
- cleaning;
- SQL;
- KPI;
- chart;
- recommendation.

## SaaS Boss Case
Goal: recurring-revenue/retention review.

Skills:
- retention definition;
- cohort/segment logic;
- SQL;
- experiment interpretation;
- executive recommendation.

## Bank Boss Case
Goal: portfolio/review workload analysis.

Skills:
- governance;
- aggregation;
- SQL;
- risk-signal interpretation;
- careful communication.

## Hospital Boss Case
Goal: capacity/wait-time operations review.

Skills:
- data validation;
- SQL;
- capacity KPI;
- visual choice;
- bounded operational recommendation.

## Logistics Boss Case
Goal: SLA and network-capacity review.

Skills:
- route aggregation;
- throughput;
- cost;
- delay investigation;
- network recommendation.

## Final capstone
Goal: compare standardized performance across all five companies and make board-level recommendations.

---

# 16. Game modes

## Career Mode
Primary progression.

## Practice Gym
Skill + difficulty filters; no career penalties.

## Review Queue
Spaced repetition.

## Daily Challenge
One rotating task per day; streak and one-time bonus.

## Weekly Case
Validated online content when configured; cached/bundled fallback offline.

## Boss Case
Multi-step end-to-end work.

## Interview Mode
Timed/untimed SQL, stats, case and behavioral rounds.

## Interview Gauntlet
Final mixed hiring simulation.

## Job Readiness
Evidence-based score; XP excluded.

## Portfolio
Strongest evidence, project cards and immutable attempt history.

---

# 17. Achievement design

Recommended initial badge catalog:

1. First Query — run first correct SQL query.
2. Clean Sweep — complete 5 cleaning tasks ≥80.
3. Spreadsheet Operator — 10 spreadsheet tasks.
4. SQL Specialist — SQL mastery ≥80.
5. Stats Skeptic — correctly reject 5 bad causal conclusions.
6. Pandas Practitioner — 10 Pandas tasks ≥75.
7. KPI Architect — 10 dashboard/KPI tasks.
8. Clear Communicator — 5 insight-writing tasks ≥85.
9. Ethics First — perfect outcome in 3 ethics/privacy events.
10. Seven-Day Streak.
11. Thirty-Day Streak.
12. Boss Case Ace — Boss Case ≥90.
13. Five Industries — complete company journey.
14. Interview Ready — Gauntlet ≥75.
15. DataQuest Graduate — satisfy certificate gates.

---

# 18. 12-week development roadmap for the v1.1 expansion

This roadmap begins from the already verified v1.0 codebase.

## Week 1 — Product/content architecture
- freeze this GDD;
- define unified content-pack schema;
- define task/dataset/dialogue/rubric database catalog;
- create migration plan preserving v1.0 state;
- establish content validation tests.

Deliverable:
- v1.1 content schema + pack loader.

## Week 2 — SQL Lab expansion
- touch shortcut bar;
- plain-language SQL error translator;
- task browser;
- window-function support/content;
- reach 20+ dedicated structured SQL tasks, then continue toward 25.

Deliverable:
- expanded SQL Lab.

## Week 3 — Spreadsheet simulator foundation
- grid/data model;
- formula cells;
- SUM/AVERAGE/IF;
- reference handling;
- touch editing;
- grading.

Deliverable:
- working spreadsheet simulator.

## Week 4 — Spreadsheet advanced + cleaning
- lookups;
- sorting;
- filters;
- pivot builder;
- cleaning actions for nulls, duplicates, formats and outliers;
- audit trail.

Deliverable:
- 15 spreadsheet + 15 cleaning tasks.

## Week 5 — Statistics expansion
- descriptive statistics;
- distributions;
- correlation;
- confidence interval;
- A/B;
- hypothesis-test interpretation;
- effect/power concepts.

Deliverable:
- 15 statistics tasks.

## Week 6 — Dashboard builder
- chart chooser;
- KPI cards;
- simple touch layout;
- rubric for chart/KPI;
- written insight box.

Deliverable:
- 15 dashboard/KPI tasks.

## Week 7 — Pandas + business metrics
- expand safe Pandas simulator;
- merge/pivot/datetime workflows;
- funnel;
- cohort;
- CAC;
- LTV;
- retention;
- simple forecasting.

Deliverable:
- 15 Pandas + expanded business metrics.

## Week 8 — Insight communication
- dedicated Write Your Insight screen;
- four-part rubric;
- manager feedback dialogues;
- rewrite/retry flow.

Deliverable:
- 10 communication tasks.

## Week 9 — Professional events
- random-event engine;
- dirty vendor data;
- urgent CEO;
- conflicting reports;
- privacy incident;
- monthly performance review integration.

Deliverable:
- 10 ethics/professional tasks + random events.

## Week 10 — Achievements and progression polish
- badge engine;
- achievement persistence;
- richer streak display;
- monthly review UI;
- offline/online indicator;
- splash/onboarding polish.

Deliverable:
- progression meta-system.

## Week 11 — Content completion and QA
- finish 140-task target;
- rebalance difficulty;
- validate every expected answer;
- cross-industry variety;
- accessibility;
- 2 GB RAM profiling;
- offline edge-case QA.

Deliverable:
- content-complete release candidate.

## Week 12 — Release
- full regression suite;
- database migration tests;
- signed AAB instructions;
- Play listing assets/copy;
- privacy/data-safety checklist;
- internal testing build;
- staged rollout plan.

Deliverable:
- v1.1 release candidate.

---

# 19. Definition of done for every new task

A task is not content-complete unless it includes:

- stable unique ID;
- skill key;
- difficulty;
- company/industry context;
- business problem;
- explicit deliverable;
- answer type;
- expected answer/result;
- three progressive hints;
- explanation;
- score/XP metadata;
- dataset reference where applicable;
- rubric where free text is graded;
- at least one automated parsing/grading validation path.

---

# 20. Design constraints

## Offline-first
Every core learning path must work without a network.

## Low-end devices
- avoid embedded Python runtime;
- page large tables;
- do not keep multiple large datasets in memory;
- prefer SQLite queries to materializing full tables;
- use lazy list builders;
- avoid heavy PDF/rendering libraries.

## Safety and integrity
- all company datasets are synthetic;
- no real bank customer data;
- no PHI;
- banking review flags are not fraud verdicts;
- hospital analytics are operational, not clinical;
- resume artifacts must not invent employer impact;
- DataQuest certificate remains a training-completion credential.

## Content extensibility
Content should be addable through versioned packs without editing task-specific Dart code whenever feasible.

---

# 21. v1.1 expansion order

The requested expansion will be executed one item at a time.

1. **Full GDD + MVP content matrix** — this document.
2. Flutter setup-from-scratch documentation + splash/navigation polish.
3. Unified SQLite content catalog + versioned JSON pack loader.
4. SQL Lab expansion + 20-task structured curriculum.
5. Spreadsheet simulator + cleaning module + 15 tasks.
6. Statistics + dashboard-builder expansion + 15 tasks.
7. Pandas/business-metrics expansion + 15 tasks.
8. Insight-writing rubric + manager dialogues + random events + monthly review.
9. Interview/portfolio/badges/streak/daily/weekly/certificate/radar gap polish.
10. Optional-cloud/offline-indicator polish.
11. Full testing/performance/offline-edge-case/Play Store guide.
12. Additional 25-task cross-industry pack for the selected skill/level.

Per user instruction, the project must stop after each item and request confirmation before beginning the next one.
