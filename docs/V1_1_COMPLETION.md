# DataQuest v1.1 — Expansion Completion

The user requested that Expansion Items 6–12 be completed in one continuous pass.

## Item 6 — Statistics + Chart/Dashboard Builder

Complete. Analytics Studio contains 15 graded challenges: 8 statistics and 7 dashboard/KPI scenarios. Coverage includes mean/median, skew/distributions, correlation, A/B tests, false positives, power, hypothesis-test interpretation, seasonality, chart choice, KPI selection and written business insight. The technical decision and communication rubric are combined into a 100-point score.

## Item 7 — Guided Pandas + Business Metrics

Complete. The guided offline Pandas curriculum now contains 15 challenges across filtering, missing values, groupby aggregation, top-N, ratios, filtered aggregation, acquisition efficiency and gross-margin analysis. Existing business-metric career tasks remain integrated.

## Item 8 — Insight Writing + Manager Simulation

Complete. Insight Coach now contains 10 scenarios spanning all five company chapters. The deterministic rubric scores clarity, evidence, recommendation and business impact. Four manager-feedback bands, four professional random events and the existing monthly review system remain integrated.

## Item 9 — Career / Interview / Portfolio System

Complete and retained. The app already includes interview modes, native Portfolio PDF generation/share, badges, daily streaks/challenges, weekly Boss Cases, completion certificates, Job Readiness and skill-radar views. Existing evidence remains immutable during normal gameplay.

## Item 10 — Optional Cloud Features

Complete and retained. Optional Supabase account/session sync, deterministic conflict merging, privacy-minimized leaderboard publishing, remote/cached weekly cases, portable backups and offline/online diagnostics are already implemented. Core learning has no cloud dependency.

## Item 11 — Final QA + Release

Complete at source level. CI performs static analysis, full tests, accessibility checks, low-memory content-budget checks, debug APK, release AAB, split APKs and release-size gates. `docs/RELEASE_CHECKLIST_v1_1.md` records physical-device, signing and Play Store release operations that require the owner’s device/keystore/Play Console.

## Item 12 — 25-task JSON Generator

Complete. `TaskPackGenerator` creates a validated schema-v2 pack for any non-empty skill and level, defaulting to 25 tasks distributed across all five company contexts. The CLI is:

`dart run tool/generate_task_pack.dart --skill "Statistics" --level "Advanced" --count 25 --output stats_advanced_25.json`

Generated packs validate through the production `ContentPack` schema before being written.
