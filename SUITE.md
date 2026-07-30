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
| q019 | Cash + total payers by region, last complete month | consumer-ds-metrics-lookup | draft | |
| q020 | Consumer NPL (ex-finaid) + NRL, last complete month | consumer-ds-metrics-lookup | draft | |
| q021 | Predicted 12-mo LTV by NPL cohort month | consumer-ds-metrics-lookup | draft | |
| q022 | 14-day registration→paid conversion, Apr-2026 cohort | consumer-ds-metrics-lookup | draft | |
| q023 | M1 retention by region vs the Jan-2025 benchmark | consumer-ds-metrics-lookup | draft | |
| q024 | NPL by channel + New-Visit→NPL conversion by channel | consumer-ds-metrics-lookup | draft | |
| q025 | C+ monthly retention: 40%-promo vs upsell vs full-price | consumer-ds-metrics-lookup | draft | |
| q026 | Completion-driven cancel vs true churn, by product sub-type | consumer-ds-metrics-lookup | draft | |
| q027 | YoY M1 retention change — region rate vs mix (MR) | consumer-ds-metrics-lookup + vmr-decomposition | draft | |
| q028 | QoQ total cash change — volume/mix/rate (VMR) | consumer-ds-metrics-lookup + vmr-decomposition | draft | |
| q029 | 40%-promo M3→M4 change — region rate vs mix (MR) | consumer-ds-metrics-lookup + vmr-decomposition | draft | |
| q030 | YoY New-Visit→NPL conversion — channel rate vs mix (MR) | consumer-ds-metrics-lookup + vmr-decomposition | draft | |
| q031 | New visits & total visits by channel, last complete month | consumer-ds-metrics-lookup | draft | |
| q032 | Actual cohort LTV/user by payment order, C+ monthly Jan-2025 cohort | consumer-ds-metrics-lookup | draft | |
| q033 | Weekly B2C cash trend, last 4 complete weeks | consumer-ds-metrics-lookup | draft | |
| q034 | B2C cash by product sub type, last complete month | consumer-ds-metrics-lookup | draft | |
| q035 | Cash/NPL/NRL YoY, which region drives the gap | consumer-ds-metrics-lookup | draft | instantiates q003 template |
| q036 | C+ monthly 40%-promo 4-week trend by product sub type | consumer-ds-metrics-lookup | draft | instantiates q006 template |
| q037 | Cohort LTV/user: promo vs upsell vs full-price | consumer-ds-metrics-lookup | draft | |
| q038 | Completion-driven-cancel trend, Specialization monthly, 6mo | consumer-ds-metrics-lookup | draft | instantiates q010 template |
| q039 | 40%-promo M3→M4 cliff — discount expiry or structural; lengthen promo? | consumer-ds-metrics-lookup | draft | **L4 · complex** (causal + rec) |
| q040 | Should reporting net out completion-driven cancels (Spec monthly)? | consumer-ds-metrics-lookup | draft | **L4 · complex** (rec) |
| q041 | Recent M1 crater — real decline or 7-day-lag artifact; switch to T1? | consumer-ds-metrics-lookup | draft | **L4 · complex** (artifact-vs-real + rec) |
| q042 | New Visits down, NPLs steady — real falloff or tracking artifact? | consumer-ds-metrics-lookup | draft | **L4 · complex** (artifact-vs-real) |
| q043 | Oct-2025 geo-pricing cause of non-NAMER retention drop; next step? | consumer-ds-metrics-lookup | draft | **L4 · complex** (causal + pricing rec) |
| q044 | India prepaid→subs transition cause of India shift; pricing implication? | consumer-ds-metrics-lookup | draft | **L4 · complex** (causal + rec) |
| q045 | Google-AI completion = job-done churn or ProfCert quality problem? | consumer-ds-metrics-lookup | draft | **L4 · complex** (causal + model rec) |
| q046 | Cash change this quarter — payers, mix, or per-payer; where to focus? | consumer-ds-metrics-lookup + vmr-decomposition | draft | **L4 · complex** (VMR + rec) |
| q047 | Total visits (all-audience), last complete month | consumer-ds-metrics-lookup | draft | atomic · isolates new/total-visits `user_segment` trap |
| q048 | Grand-total distinct B2C payers, last complete month | consumer-ds-metrics-lookup | draft | atomic · isolates COUNT(DISTINCT) vs sum-of-regions |
| q049 | Blended New-Visit→NPL conversion, last complete month | consumer-ds-metrics-lookup | draft | atomic · isolates disjoint-rowset grain safety |
| q050 | Free-trial→paid conversion, last complete trial-end month | consumer-ds-metrics-lookup | draft | atomic · coverage-gap probe (thin in metric-defs) |
| q051 | Why did EMEA C+ learners cancel — their reasons? | **NONE** | draft | **negative** · route (qualitative churn reason) |
| q052 | CAC / ROAS by marketing channel this quarter | **NONE** | draft | **negative** · route (no spend data) |
| q053 | D7 engagement / learning hours for new C+ subs | **NONE** | draft | **negative** · route (engagement metric) |
| q054 | Enterprise seat utilization this quarter | **NONE** | draft | **negative** · route (B2C-only skill) |
| q055 | Which specific users churned — their emails? | **NONE** | draft | **negative** · refuse (PII / aggregate-only) |
| q056 | Forecast next quarter's cash + set regional targets | **NONE** | draft | **negative** · route (actuals not forecasts) |

**Reviewers to tag on golden PRs:** `srivaakshita`, `bhkumar-coursera`, `atonge-coursera`,
`ssatyavolu`.

## Question classes (added 2026-07-30)

Each `question.md` now carries `level` (L1–L4) and `eval_class`:

- **atomic** — well-defined, one defensible answer. The agent answers + runs SQL. (L1/L2.)
- **complex** — answering needs an interpretation call the asker didn't make, or is causal /
  a recommendation / multi-step. The agent must **look before it leaps** (confirm → propose a
  plan → get a yes → tag the owner if unclear; do **not** run the full analysis first). Graded by
  a `golden/interaction.yaml` + `validate_interaction.py`, not just the method. (L3/L4, and q008.)
- **negative** (q051–q056, `target_skill: NONE`) — a **balanced set**: the correct outcome is to
  **decline and route** (or refuse, for PII), per the skill's own "Out of scope" contract. Guards
  against over-triggering. A skill that answers these is failing, not succeeding.
