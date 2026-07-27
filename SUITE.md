# Consumer eval suite

Every question below comes from the Consumer DS pod's own question list
(`skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/questions.md`). We test
**all** of them, not a sample.

**Scope:** B2C consumer metrics only (`consumer_ds`). The pod's `degree_ds` questions are a
separate suite.

**Status:** `draft` → `approved` → `frozen`. Every question here is `draft` — this is the
seed. Golden answers get added later, one PR per question.

## Two things to sort out during review

1. **Template questions** (marked *needs instantiation*): these have placeholders like
   `[KPI]` / `[dimension]`. A codeowner needs to turn each into one concrete question before
   we can freeze an answer.
2. **Questions with no skill yet** (marked *skill not built*): the "why did it move" (RCA)
   questions route to `consumer-ds-metric-rca`, which the metrics-lookup SKILL.md lists as
   *to be built*. These are real stakeholder questions with no recipe yet — a coverage gap.

## Questions

| ID | Question (short) | Target skill | Status | Note |
|----|------------------|--------------|--------|------|
| q001 | KPI by dimension, YoY | consumer-ds-metrics-lookup | draft | needs instantiation (template) |
| q002 | Dimension mix shift over time | consumer-ds-metrics-lookup | draft | needs instantiation (template) |
| q003 | Cash/NPL/NRL this month vs LY, which region drives the gap | consumer-ds-metrics-lookup | draft | |
| q004 | Retention now: M1→M2 vs M2+ | consumer-ds-metrics-lookup | draft | |
| q005 | Total payers MTD vs last month and last year | consumer-ds-metrics-lookup | draft | |
| q006 | C+ monthly 40%-off promo, 4-week trend, promo vs non-promo | consumer-ds-metrics-lookup | draft | |
| q007 | Retention M1→M12: discount vs upsell vs full-price | consumer-ds-metrics-lookup | draft | |
| q008 | C+ monthly M1/M2/M2+ retention, biggest drop-off | consumer-ds-metrics-lookup | **frozen** | certified by @bhkumar-coursera vs Looker (PR #112) |
| q009 | Retention monthly vs annual, first vs repeat renewal | consumer-ds-metrics-lookup | draft | |
| q010 | Terminal-sub completion drop-off, trend over time | consumer-ds-metrics-lookup | draft | |
| q011 | Full 12-month retention curve, Jan 2026 C+ monthly cohort, YoY | consumer-ds-metrics-lookup | draft | |
| q012 | Decompose YoY retention change by dimension | consumer-ds-metrics-lookup | draft | needs instantiation (template) |
| q013 | Registrations by geo/device, % paid within 14 days | consumer-ds-metrics-lookup | draft | |
| q014 | Which channel drives most NPLs, how well they retain | consumer-ds-metrics-lookup | draft | |
| q015 | New-visit→NPL conversion, trend by channel | consumer-ds-metrics-lookup | draft | |
| q016 | M2 retention fell off a cliff around Mar 17 2026 — why | consumer-ds-metric-rca | draft | skill not built |
| q017 | E2C traffic surge since Mar 11, Direct dipped — real or re-attribution | consumer-ds-metric-rca | draft | skill not built |
| q018 | Homepage registrations down 3 weeks — why | consumer-ds-metric-rca | draft | skill not built |

**Reviewers to tag on golden PRs:** `srivaakshita`, `bhkumar-coursera`, `atonge-coursera`,
`ssatyavolu`.
