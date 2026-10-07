# DataQuest v1.3 — Product & Job-Readiness Audit

## Goal

Make DataQuest feel less like a menu of learning utilities and more like a complete career simulator that can take a learner from zero knowledge to credible junior data-analyst job readiness.

## Product flaws found

1. **Flat beginner curriculum.** The v1.2 Academy exposes all lessons at once. That is good for browsing but weak for momentum, progression and decision reduction.
2. **Too much guided learning without a clear independence ladder.** Hints and worked examples are useful early, but job readiness requires a deliberate transition to assisted and then independent work.
3. **Exercises are often isolated.** The labs are strong individually, but a real analyst works through connected requests where cleaning, SQL, statistics, KPI design and communication influence one another.
4. **The career fantasy is underused.** Companies, roles and manager context exist, but the normal session still feels like choosing tools from a menu rather than reporting to work.
5. **Power BI / semantic modeling is missing as a first-class skill.** Dashboard design alone does not teach Power Query, star schemas, DAX measures, filter context, date tables, relationships, RLS or BI release QA.
6. **Skill progression is measured mainly by mastery %.** Learners need to see a job-readiness ladder: Learn → Practice → Project → Interview-ready.
7. **Portfolio evidence exists but is not consistently created by connected project work.** Isolated task evidence is useful, but recruiters value coherent business projects and the ability to explain decisions.
8. **Content depth is uneven.** Python/Pandas starts too close to DataFrames for a true zero-knowledge learner, and several statistics concepts were compressed into large lessons.
9. **The Home screen has a next action but not a strong workday loop.** A learner should be able to open the app and immediately understand what company problem they are solving and why it matters.
10. **The mastery system was not future-proof for new skills.** Adding a skill such as Power BI should not require fragile special-case persistence logic.
11. **Gamification risks becoming points without competence.** XP is useful for motivation, but project completion, independent performance and portfolio evidence must carry more meaning than repeated easy tasks.
12. **The bridge from lessons to Boss Cases is too large.** Learners need smaller connected missions before the large end-to-end cases.

## v1.3 implementation direction

- Expand foundation curriculum to **80 lessons** across SQL, Excel, Cleaning, Statistics, Python/Pandas, Dashboards/KPIs, Power BI/BI Modeling and Business Analytics.
- Make Academy tracks sequential with visible progress and three stages: **Guided → Assisted → Independent**.
- Add Python fundamentals before Pandas and deepen statistics into test selection, chi-square, regression, power/MDE and practical significance.
- Add Power BI foundations plus hands-on BI decision challenges.
- Add **12 connected Career Missions** across five companies. Each mission has a manager briefing, deadline, multiple real tasks, project bonus, manager feedback and a resume-ready evidence statement.
- Record completed missions as portfolio evidence.
- Add a job-ready skill map showing Learn → Practice → Project → Interview-ready.
- Improve first-run choice: true beginner can start from zero; experienced learner can take placement.
- Keep solutions available, but preserve the 5 XP solution penalty.
- Preserve offline-first behavior, stable IDs and existing progress.

## Product standard

A feature should remain only if it helps at least one of these:
1. learn a concept,
2. practice it,
3. apply it in a realistic project,
4. explain the result,
5. prove job readiness.

Decorative gamification that does not reinforce competence should not become the core loop.
