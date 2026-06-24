---
name: consumer-ds-metrics-lookup
description: "Consumer (B2C) retention & acquisition metric lookup — given a metric, a date range, and an optional segmentation, returns the number computed the canonical way. Use when asked about cash, NPLs (new paying learners), NRLs (new registered learners), new visits, total payers, retention (M1 / M2 / M2+ / M12 renewal rates), the C+ monthly 40%-off-3-months promo, promo vs upsell vs full-price, 14-day registration-to-paid conversion, new-visit-to-NPL conversion, completion-driven cancel vs churn, or LTV — sliced by region, marketing channel, product sub type, monthly vs annual, YoY / WoW / MTD. Mentions base_data_for_ret_cancel, tof_consolidated_tracking_table, next_txn_stamp_sub_level, cash_receipt_usd_estimate, payment_order, country_group_finance."
---

# Consumer & Degree Strategy DS — Metrics Lookup (consumer_ds)

Metric-pull skill for the **Consumer Strategy DS** pod's B2C subscription metrics. Given a metric
name + date range + optional segmentation, it returns the number computed the same way the pod's
dashboards do. It is the lego brick the `consumer-ds-metric-rca` skill assembles on.

## When to Use This Skill
- "How are we tracking on cash, NPLs and NRLs this month vs the same period last year — and which region's driving the gap?"
- "Where are we on total payers month-to-date, and how does that trend against last month and last year?"
- "What's our [KPI] for [time period] by [region / channel / product sub type], YoY?"
- "What are M1, M2 and M2+ retention for C Plus monthly, and where's the biggest drop-off?"
- "How does retention compare for monthly vs annual plans, splitting first renewal from repeat (M2+)?"
- "Show the full 12-month retention curve for the Jan 2026 C Plus monthly cohort, year-over-year."
- "How's the C+ monthly 40%-off-3-months promo doing? 4-week trend across product sub-types, promo vs non-promo?"
- "What does retention look like from M1 to M12 for 40%-discount subs vs upsell vs full-price?"
- "How are registrations / new visits trending by geo/device, and what % convert to paid within 14 days?"
- "Which marketing channel drives the most NPLs, and what's the new-visit-to-NPL conversion by channel?"
- "For terminal cert/spec subs, how much of the drop-off is learners completing the s12n (a 'good' cancel) vs true churn?"
- "What's the predicted 12-month LTV of this month's NPLs, and how does cohort LTV/user build for C+ monthly?"

> For **why a metric moved** (e.g. "M2 fell off a cliff around March 17 — what's driving it?"),
> use the **`consumer-ds-metric-rca`** skill instead — this skill returns the *number*, not the *cause*.

## Workflow
1. **Clarify scope.** Confirm: which metric, date range, product sub type (or **all** — the default),
   segment (region / channel / promo-vs-upsell-vs-full-price / monthly vs annual), and comparison
   (WoW / YoY / MTD). Default to the **last complete month**.
2. **Pick the metric.** Look it up in [references/metric-definitions.md](references/metric-definitions.md)
   for the canonical formula, source table, grain, date column, standard filters, and caveats.
3. **Pick the lens (NRL & NPL only).** Aggregate / trend by channel·geo·date → the **TOF** table;
   funnel / "users who paid" drill-downs → **user-level** tables. Don't mix the two in one view.
4. **Build the query** from [references/common-queries.md](references/common-queries.md). Always apply
   the standard B2C filters; for TOF add the invalid-traffic exclusion + last-complete-month cap and
   `user_segment='B2C'` (for NRL/NPL); for user-level tables add the B2C user filter (exclude
   enterprise + degree). See [references/table-schema.md](references/table-schema.md) for columns + joins.
5. **Run it** via the Databricks MCP read-only tool (`execute_sql_read_only`; poll with
   `poll_sql_result` if a `statement_id` is returned). If the MCP isn't connected, show the validated
   SQL and tell the user to run it manually.
6. **Format the result** and state the filters / segment / period used. Reconcile to the owning Looker
   dashboard before quoting externally. Flag any cohort **<50 subs** as statistically unreliable.

## Quick Start
**M1 / M2 / M3 step retention for C+ monthly (reproduces the documented Jan-2025 benchmark to the decimal):**
```sql
SELECT payment_order,
       ROUND(COUNT(next_txn_stamp_sub_level) * 100.0 / COUNT(*), 1) AS renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line = 'B2C' AND transaction_type = 'BUY'
  AND product_sub_type = 'C Plus monthly' AND was_buy_transaction_refunded = FALSE
  AND recurring_payment_end_ts < CURRENT_DATE() - INTERVAL 7 DAYS
  AND DATE_TRUNC('month', transaction_dt) = DATE'2025-01-01'
  AND payment_order BETWEEN 1 AND 3
GROUP BY payment_order ORDER BY payment_order;
-- M2+ = same filters with payment_order >= 2, no GROUP BY.
```

## Reference Files
| File | Use When |
|------|----------|
| [references/metric-definitions.md](references/metric-definitions.md) | You need the canonical formula, source table, grain, filters, or caveats for a metric (synced copy of the pod's `metrics.md`). |
| [references/table-schema.md](references/table-schema.md) | You need the column list / types for a table, how the tables join, or which lens (TOF vs user-level) to use. |
| [references/common-queries.md](references/common-queries.md) | You need a worked, verified query for a question-shape: step retention, 12-month curve, promo/upsell/full-price split, channel split, conversion, LTV, completion-vs-churn, or a rate-vs-mix (VMR) decomposition. |

## Out of Scope — decline, then route to **Consumer Strategy DS**
The agent must **decline and route to the Consumer Strategy DS team** (single front door) — and
**refuse rather than hallucinate** a table, column, or number — for:
- **Qualitative churn *reasons* / motivations** (rates only here; no survey / NPS / sentiment / cancel-reason text).
- **Data freshness / pipeline / ETL status** (Data Engineering; this skill only states the freshness caveat).
- **Payment failure / dunning / billing mechanics** (the 7-day retry window is *assumed*, not analyzed).
- **Individual learner data / PII** — aggregate only (FERPA / GDPR / CCPA); no per-user lookups.
- **Enterprise (B2B) & Degrees metrics** — this skill is B2C consumer only.
- **Engagement / learning-outcome metrics** (D1-W4, M1 PER, hours) — Engagement pod (s12n completion is used here only to split a "good" cancel from churn).
- **Marketing spend / CAC / ROAS** — TOF has no cost data.
- **Forecasts / targets / financial planning / VAT / accounting** — actuals + the predicted-LTV model output only.
- **Causal / A-B experiment readouts** — beyond the VMR rate-vs-mix decomposition.
- **Any table not documented in this skill** — say so and stop.

## Related Skills
- **`consumer-ds-metric-rca`** — explains *why* a consumer metric moved (assembles on this skill). *(to be built — Step 5)*
- The pod's **VMR (volume-mix-rate) decomposition** workflow — for "rate vs mix" / "how much did each segment contribute" questions.
- `skills/platform/databricks-sql` — SQL syntax + Databricks MCP usage.
- `skills/data-science/engagement` — engagement / learning-outcome metrics (explicitly out of scope here).
