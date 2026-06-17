# Consumer & Degree Strategy DS — Canonical Metrics

Canonical definitions for every KPI in `questions.md`. **One metric → one canonical source.**
Every SQL block below was **run live against Databricks**; the Retention example reproduces the
documented benchmark to the decimal. `[TBD]` marks a source-of-truth link still to confirm.

**Standard dimensions:** Region (`country_group_finance`: NAMER / EMEA / LatAm / Non-India APAC / India) · Geo (country, IP-based — caveat below) · Product Sub Type · Channel (L0→L3 marketing taxonomy).

**Two-lens rule (NRL & NPL):** aggregate / trend by channel·geo·date → **TOF** table; funnel / "users who paid" drill-downs → **user-level** tables. The two need not tie to the same number — don't mix them in one view.

**Verified base-table fact:** for B2C, `prod.bi.base_data_for_ret_cancel` contains **only** `transaction_type='BUY'` rows with `was_buy_transaction_refunded=FALSE`, and `cash_receipt_usd_estimate` ≡ `transaction_amount_usd_estimate` (0 mismatches, 2024–2026). So CLAUDE.md Rule 2 (BUY) and Rule 6 (refunded=FALSE) are **defensive no-ops** on this table — kept for clarity and robustness, not because they filter anything today.

**Verified TOF-grain fact:** in `prod.bi.tof_consolidated_tracking_table`, `new_visits`/`visits` are populated **only** on `user_segment IS NULL` (all-audience) rows; `nrls`/`npls` are populated **only** on segment-labeled rows (`B2C` / `B2B_ENTERPRISE` / `DEGREES`). Consequences:
- `SUM(new_visits)` over all rows does **not** multi-count — but **never** group/filter visits by `user_segment` (they're 0 there).
- For Consumer NRL/NPL you **must** filter `user_segment='B2C'`.

**Data freshness:** base_data updates daily, last ~2 days incomplete; TOF — report only through the **last complete month**. As of 2026-06-16 that is **May 2026** (`DATE'2026-05-01'`).

---

## Metric: Cash
- **Definition:** USD cash from completed (non-refunded) B2C subscription payments in the period.
- **SQL formula:** `SUM(cash_receipt_usd_estimate)` *(≡ `SUM(transaction_amount_usd_estimate)` in this table)*
- **Source table:** `prod.bi.base_data_for_ret_cancel`
- **Grain:** payment event → aggregate to month
- **Date column:** `transaction_dt`
- **Standard segmentations:** Region (`country_group_finance`), Product Sub Type
- **Standard filters:** `transaction_business_line='B2C'`, `transaction_type='BUY'`, `was_buy_transaction_refunded=FALSE`
- **Owner / source of truth:** `[TBD — confirm Finance/BI dashboard]`
- **Known caveats:**
  - This table holds only non-refunded B2C buys, so it is **cash from payments that stuck**, *not* cash netted of refunds processed in a later month. **Confirm with Finance** whether the official Cash KPI nets later refunds from another source — `[TBD]`.
  - A tiny `NULL` `country_group_finance` bucket (~tens of rows/mo) appears in the regional split but is captured by the grand total — surface as "Unknown" or footnote it.
  - Last ~2 days incomplete; use only fully-matured months for trends.

```sql
-- Net cash by region, last complete month
SELECT country_group_finance,
       ROUND(SUM(cash_receipt_usd_estimate)) AS net_cash_usd
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY' AND was_buy_transaction_refunded=FALSE
  AND DATE_TRUNC('month', transaction_dt)=DATE'2026-05-01'
GROUP BY 1 ORDER BY 2 DESC;
```

---

## Metric: NPL — New Paying Learners
- **Definition:** Distinct learners who made their first-ever unrefunded B2C payment in the period (excludes financial-aid users).
- **SQL formula:**
  - *Overall / trend (canonical):* `SUM(npls)` with `user_segment='B2C'` and `user_finaid_status <> 'FINAID_user'`.
  - *User-level (funnel lens):* `COUNT(DISTINCT user_id)` from `base_data_for_ret_cancel` where `transaction_ts = first_unrefund_payment_ts` (join `user_stats_vw`), `(payment_order=1 OR payment_order IS NULL)`, `was_buy_transaction_refunded=FALSE`, B2C user filter applied.
- **Source table:** `prod.bi.tof_consolidated_tracking_table` (overall) · `prod.bi.base_data_for_ret_cancel` + `prod.gold.user_stats_vw` (user-level)
- **Grain:** TOF = `event_dt` × channel × geo × segment · user-level = one row per new payer
- **Date column:** `event_dt` (TOF) · `transaction_dt` (user-level)
- **Standard segmentations:** Channel (`referrer_cons_l0–l3_mktg_chnl`), Region/Geo, Product Sub Type
- **Standard filters:** TOF → `user_segment='B2C'` **(required)** + ex-finaid + invalid-traffic exclusion + last-complete-month. User-level → B2C user filter.
- **Owner / source of truth:** TOF V4 `[TBD — confirm dashboard]`
- **Known caveats:**
  - **Must** include `user_segment='B2C'` — omitting it inflates NPL ~+11% (enterprise + degree payers leak in).
  - `user_finaid_status <> 'FINAID_user'` silently drops NULL-status rows, but those carry 0 NPLs, so it equals `='Non-FINAID_user'` for this metric.
  - Two-lens rule applies; for channel splits use the *payment* channel columns, not registration columns.
  - June-style partial months understate; report through last complete month.

```sql
-- Consumer NPL (ex-finaid), last complete month
SELECT SUM(npls) AS consumer_npls_exfinaid
FROM prod.bi.tof_consolidated_tracking_table
WHERE user_segment='B2C'
  AND user_finaid_status <> 'FINAID_user'
  AND DATE_TRUNC('month', event_dt)=DATE'2026-05-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'));
```

---

## Metric: NRL — New Registered Learners
- **Definition:** Distinct learners who registered (created an account) in the period.
- **SQL formula:**
  - *Overall / trend (canonical):* `SUM(nrls)` with `user_segment='B2C'`.
  - *User-level (funnel lens):* `COUNT(DISTINCT user_id)` from `users_vw` where `registration_ts` falls in the period (B2C user filter applied).
- **Source table:** `prod.bi.tof_consolidated_tracking_table` (overall) · `prod.gold.users_vw` (user-level funnel)
- **Grain:** TOF = `event_dt` × channel × geo × segment · users_vw = one row per registrant
- **Date column:** `event_dt` (TOF) · `registration_ts` (users_vw)
- **Standard segmentations:** Channel, Region/Geo, device (`registration_os_l1` / `_client` / `_device_family`)
- **Standard filters:** TOF → `user_segment='B2C'` + invalid-traffic exclusion + last-complete-month. users_vw → B2C user filter.
- **Owner / source of truth:** TOF V4 `[TBD — confirm dashboard]`
- **Known caveats:**
  - `SUM(nrls)` is event-grained (summed across channel/geo rows), not a strict `COUNT(DISTINCT learner)`; TOF aggregate ≠ user-level count exactly (two-lens rule).
  - `country_cd` is IP-based — group by `country_group_finance`.
  - Invalid-traffic exclusion trims only ~0.3% of B2C NRL but keep it for consistency with the TOF suite.

```sql
-- Consumer NRL, last complete month
SELECT SUM(nrls) AS nrls_consumer
FROM prod.bi.tof_consolidated_tracking_table
WHERE user_segment='B2C'
  AND DATE_TRUNC('month', event_dt)=DATE'2026-05-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'));
```

---

## Metric: New Visits (and Total Visits)
- **Definition:** Count of new (first-time) visits to Coursera in the period. `Total Visits` = `SUM(visits)` is the all-visits companion.
- **SQL formula:** `SUM(new_visits)` · `SUM(visits)` for Total Visits.
- **Source table:** `prod.bi.tof_consolidated_tracking_table`
- **Grain:** `event_dt` × channel × geo (all-audience; carried on `user_segment IS NULL` rows)
- **Date column:** `event_dt`
- **Standard segmentations:** Channel (`referrer_cons_l0–l3_mktg_chnl`), Region/Geo
- **Standard filters:** invalid-traffic exclusion; cap `event_dt` at last complete month. **Do NOT add `user_segment`** — visits are 0 on segment rows.
- **Owner / source of truth:** TOF V4 `[TBD — confirm dashboard]`
- **Known caveats:**
  - `new_visits`/`visits` live **only** on `user_segment IS NULL` rows; grouping/filtering by `user_segment` collapses them to ~0. Use segment splits only for NRL/NPL.
  - Invalid-traffic exclusion removes ~10% of visits (mostly CN-Direct) — always apply it.
  - `new_visits/total_visits` (~60%) is a returning-visitor ratio; a sudden swing usually signals a cookie/identity tracking change, not real demand.

```sql
-- New Visits + Total Visits, last complete month (all-audience; no user_segment filter)
SELECT DATE_TRUNC('MONTH', event_dt) AS month,
       SUM(new_visits) AS new_visits,
       SUM(visits)     AS total_visits
FROM prod.bi.tof_consolidated_tracking_table
WHERE event_dt >= DATE'2026-05-01' AND event_dt < DATE'2026-06-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'))
GROUP BY 1;
```

---

## Metric: Total Payers
- **Definition:** Distinct learners who made any B2C payment (BUY) in the month — new and renewing.
- **SQL formula:** `COUNT(DISTINCT user_id)`
- **Source table:** `prod.bi.base_data_for_ret_cancel`
- **Grain:** distinct user × month
- **Date column:** `transaction_dt`
- **Standard segmentations:** Region, Product Sub Type
- **Standard filters:** `transaction_business_line='B2C'`, `transaction_type='BUY'`, `was_buy_transaction_refunded=FALSE`
- **Owner / source of truth:** `[TBD — confirm dashboard]`
- **Known caveats:**
  - Counts new + renewing payers, deduped per month — **always exceeds** NPL/new-acquisition counts; it is not NPL.
  - Compute the grand total with a single `COUNT(DISTINCT user_id)`, not by summing regions (a user could span regions across months).
  - Small `NULL` region bucket (~tens of payers) — footnote or label "Unknown".
  - MTD: pace against the *same day-of-month* in the prior period, not the full-month total.

```sql
-- Total Payers by region + grand total, last complete month
SELECT country_group_finance, COUNT(DISTINCT user_id) AS total_payers
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY' AND was_buy_transaction_refunded=FALSE
  AND DATE_TRUNC('month', transaction_dt)=DATE'2026-05-01'
GROUP BY 1 ORDER BY 2 DESC;
-- Grand total: same filters, COUNT(DISTINCT user_id) with no GROUP BY.
```

---

## Metric: Retention rate (MN renewal rate)
- **Definition:** % of subscribers at payment N who renew to payment N+1 on the **same** subscription. "M2+" = repeat renewals (`payment_order >= 2`).
- **SQL formula:** `COUNT(next_txn_stamp_sub_level) * 100.0 / COUNT(*)` at `payment_order = N`
- **Source table:** `prod.bi.base_data_for_ret_cancel`
- **Grain:** subscription × payment step
- **Date column:** `recurring_payment_end_ts` (eligibility & billing month) · `transaction_dt` (cohort month)
- **Standard segmentations:** Product Sub Type, Region, segment (40% promo / upsell / full price), monthly vs annual
- **Standard filters:** `B2C`, `BUY`, renewal via `next_txn_stamp_sub_level` (**never** `next_txn_stamp`), general eligibility `recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS`, `was_buy_transaction_refunded=FALSE`. (T1 = 2-day lag + `next_txn_stamp_sub_level <= recurring_payment_end_ts + INTERVAL 1 DAY`, only if asked.)
- **Owner / source of truth:** `knowledge_base/metric/retention_rate.md` · `[TBD — Looker]`
- **Known caveats:**
  - 7-day eligibility lag — recent cohorts look artificially low until the payment-retry window closes; use T1 for near-real-time monitoring.
  - Benchmark (C+ monthly, Jan-2025 cohort, **verified to the decimal**): M1 62.6% → M2 67.8% → M3 74.8% → M4 78.5% → M5 79.5%. Rises with tenure.
  - These are step (conditional) renewal rates anchored on the `transaction_dt` billing month — **not** a single-cohort survival curve (see derived curve query in `references/common-queries.md`).
  - Cert/spec products: completing the s12n auto-cancels the sub — split "good" completion-cancels from true churn (see next metric). Cohort <50 subs → flag as unreliable.

```sql
-- M1–M5 step retention, C+ monthly, Jan-2025 cohort (reproduces benchmark)
SELECT payment_order,
       COUNT(*)                                                 AS eligible_subs,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
  AND DATE_TRUNC('month', transaction_dt)=DATE'2025-01-01'
  AND payment_order BETWEEN 1 AND 5
GROUP BY payment_order ORDER BY payment_order;
-- M2+ = same filters with payment_order >= 2 and no GROUP BY.
```

---

## Metric: Completion-driven cancel vs true churn  *(completion-eligible products)*
- **Definition:** Among **ended** subscriptions for completion-eligible products (Specialization / Gateway / Professional Certificate monthly), the share whose cancel was driven by **completing the specialization** (a "good" cancel) vs **true churn**. Finishing an s12n auto-ends the sub.
- **SQL formula:** of ended subs, `completion_driven = phoenix_specialization_completion_ts` present at/near `recurring_payment_end_ts`; `true_churn` = the rest.
- **Source table:** `prod.bi.base_data_for_ret_cancel` (ended subs) ⨝ `prod.gold.phoenix_specialization_enrollments_derived_metrics_vw` (completion). Join key (verified 99.99%): `underlying_product_item_id = phoenix_specialization_id`.
- **Grain:** subscription (ended)
- **Date column:** `recurring_payment_end_ts` (matured cohort)
- **Standard segmentations:** Product Sub Type (Specialization / Gateway / Professional Certificate monthly)
- **Standard filters:** B2C/BUY, `rn1=1`, `next_txn_stamp_sub_level IS NULL` (no same-sub renewal), matured month + 7-day eligibility lag.
- **Owner / source of truth:** `knowledge_base/note/s12n_completions.md` · `[TBD — BI/analytics owner]`
- **Known caveats:**
  - Completion-driven cancels are a **success**, not loss — never net them into churn/retention for these products. **Does NOT apply to C+** (all-access pass).
  - Verified Mar-2026 Specialization-monthly cohort: ~21% completion-driven / ~79% true churn (window choice moves the split <1pp).
  - Completion records are **learner education data (FERPA/GDPR)** — keep output aggregate; confirm the canonical completion definition with the BI/analytics owner before external publishing.
  - Uses the blessed `prod.gold.*_vw`, **not** `coursera_warehouse.edw_core.*` — the `_vw` is verified identical (same Mar-2026 split to the row). `phoenix_specialization_completion_ts` is typed `string` in the view; the `<=` timestamp comparison relies on implicit cast (add `::timestamp` if you want it explicit).
  - `prod.bi.subscriptions` has **no** `subscription_inactivation_ts` (base_data does) — prefer base_data for the ended-sub definition.

```sql
WITH ended_subs AS (   -- ended Specialization-monthly subs in a matured month
  SELECT subscription_id, user_id,
         underlying_product_item_id AS phoenix_specialization_id,
         recurring_payment_end_ts
  FROM prod.bi.base_data_for_ret_cancel
  WHERE transaction_business_line='B2C' AND transaction_type='BUY' AND was_buy_transaction_refunded=FALSE
    AND product_sub_type='Specialization monthly'
    AND rn1=1 AND next_txn_stamp_sub_level IS NULL
    AND recurring_payment_end_ts >= DATE'2026-03-01' AND recurring_payment_end_ts < DATE'2026-04-01'
    AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
),
completion AS (
  SELECT user_id, phoenix_specialization_id,
         MIN(phoenix_specialization_completion_ts) AS completion_ts
  FROM prod.gold.phoenix_specialization_enrollments_derived_metrics_vw
  WHERE phoenix_specialization_completion_ts IS NOT NULL
  GROUP BY 1,2
)
SELECT CASE WHEN c.completion_ts IS NOT NULL
            AND c.completion_ts <= e.recurring_payment_end_ts + INTERVAL 7 DAYS
            THEN 'completion_driven_cancel' ELSE 'true_churn' END AS cancel_reason,
       COUNT(*) AS ended_subs,
       ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER (), 1) AS pct_of_ended
FROM ended_subs e
LEFT JOIN completion c ON e.user_id=c.user_id AND e.phoenix_specialization_id=c.phoenix_specialization_id
GROUP BY 1 ORDER BY 2 DESC;
```

---

## Derived metrics

### 14-day registration → paid conversion rate
- **Definition:** Of learners who registered in a (matured) period, the % who made a first B2C payment within 14 days.
- **SQL formula:** `converters_14d / registrants`, where a converter has a `(payment_order=1 OR NULL)` BUY with `DATEDIFF(DAY, registration_ts, transaction_dt) BETWEEN 0 AND 14`.
- **Source:** `prod.gold.users_vw` (denominator) ⨝ `prod.bi.base_data_for_ret_cancel` (numerator); B2C user filter applied. See `knowledge_base/note/registration_to_retention_funnel.md`.
- **Standard segmentations:** Region/Geo, device (`registration_os_l1`/`_client`/`_device_family`), Channel.
- **Known caveats:**
  - Cohort month must be ≥14 days matured — use a complete past month (not the in-progress one).
  - `DATEDIFF` is day-level inclusive (spans 15 calendar days); tighten to `<15` or use timestamps for a strict 14×24h window.
  - B2C filter excludes users *ever* in enterprise/degree (lifetime), which can slightly understate the historical consumer cohort.
  - Verified Apr-2026 cohort ≈ **4.2%** (low single-digit, as expected).

```sql
WITH regs AS (
  SELECT u.user_id, u.registration_ts
  FROM prod.gold.users_vw u
  LEFT ANTI JOIN prod.gold.enterprise_contract_program_memberships_vw e ON u.user_id=e.user_id
  LEFT ANTI JOIN prod.gold_base.degree_course_session_enrollments d ON u.user_id=d.user_id
  WHERE DATE_TRUNC('month', u.registration_ts)=DATE'2026-04-01'
),
conv AS (
  SELECT DISTINCT r.user_id
  FROM regs r JOIN prod.bi.base_data_for_ret_cancel b ON b.user_id=r.user_id
  WHERE b.transaction_business_line='B2C' AND b.transaction_type='BUY'
    AND (b.payment_order=1 OR b.payment_order IS NULL) AND b.was_buy_transaction_refunded=FALSE
    AND DATEDIFF(DAY, r.registration_ts, b.transaction_dt) BETWEEN 0 AND 14
)
SELECT COUNT(DISTINCT r.user_id) AS registrants,
       COUNT(DISTINCT c.user_id) AS converters_14d,
       ROUND(COUNT(DISTINCT c.user_id)*100.0/COUNT(DISTINCT r.user_id), 2) AS conv_pct_14d
FROM regs r LEFT JOIN conv c ON r.user_id=c.user_id;
```

### New Visit → NPL conversion rate
- **Definition:** Share of new visits that become new paying learners in the period.
- **SQL formula:** `SUM(npls) / SUM(new_visits)` (TOF), trendable by channel.
- **Source:** `prod.bi.tof_consolidated_tracking_table` (invalid-traffic exclusion + last-complete-month).
- **Standard segmentations:** Channel (`referrer_cons_l1_mktg_chnl`), Region/Geo.
- **Known caveats:**
  - Numerator (`npls`) and denominator (`new_visits`) live on **disjoint** row sets (segment rows vs `user_segment IS NULL` rows) but share the channel dimension, so a plain `SUM/SUM` (no `user_segment` filter, no join) is grain-safe and per-channel `new_visits` re-sum to the all-audience total.
  - **Default = all-audience numerator** to keep numerator and denominator on the same basis. A B2C-only numerator (`user_segment='B2C'` npls) over an all-audience denominator is a different ratio — document which you use.
  - Apply invalid-traffic exclusion to both sides; `event_dt` is page-view date for visits but payment date for npls, so partial months understate the rate.

```sql
-- Blended New Visit → NPL conversion, last complete month (add referrer_cons_l1_mktg_chnl to GROUP BY to trend by channel)
SELECT DATE_TRUNC('MONTH', event_dt) AS month,
       SUM(new_visits) AS new_visits,
       SUM(npls)       AS npls,
       ROUND(SUM(npls)*100.0/NULLIF(SUM(new_visits),0), 4) AS nv_to_npl_pct
FROM prod.bi.tof_consolidated_tracking_table
WHERE event_dt >= DATE'2026-05-01' AND event_dt < DATE'2026-06-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'))
GROUP BY 1;
```

### LTV — cohort (actual) and predicted
- **Definition:** (1) **Cohort LTV/user** — cumulative revenue per original subscriber by payment_order. (2) **Predicted LTV** — model estimate of next-12-month LTV per NPL.
- **SQL formula:** (1) `cumulative SUM(transaction_amount_usd_estimate) / cohort_size` by `payment_order`. (2) `AVG(adjusted_predicted_ltv)` by `first_payment_dt` month.
- **Source:** (1) `prod.bi.base_data_for_ret_cancel`. (2) `prod.ml.user_level_ltv_prediction_npls_adj` (already NPL-scoped).
- **Standard segmentations:** Product Sub Type, Region, cohort month, segment (promo/upsell/full price).
- **Known caveats:**
  - (1) Denominator is the fixed `payment_order=1` cohort size → revenue per *original* subscriber, not per active. Use a matured cohort.
  - (2) Table is NPL-scoped but **not** fully B2C — ~4–5% overlap with enterprise/degree; the B2C anti-join variant changes magnitudes only marginally but is the stricter convention. `adjusted_predicted_ltv` includes VAT (`adjusted_predicted_ltv_ex_vat` for ex-VAT).
  - Verified: cohort LTV/user rises monotonically (~$50 at order 1 → ~$200 by order 18 for Jan-2025 C+ monthly); predicted LTV in low-hundreds-of-dollars range.
  - **Not in the committed `questions.md` KPI footer** — see "questions.md additions" below.

```sql
-- (1) Cohort LTV/user, C+ monthly Jan-2025
WITH c AS (
  SELECT subscription_id FROM prod.bi.base_data_for_ret_cancel
  WHERE transaction_business_line='B2C' AND transaction_type='BUY' AND product_sub_type='C Plus monthly'
    AND payment_order=1 AND was_buy_transaction_refunded=FALSE
    AND DATE_TRUNC('month', transaction_dt)=DATE'2025-01-01'
)
SELECT b.payment_order,
       ROUND(SUM(SUM(b.transaction_amount_usd_estimate)) OVER (ORDER BY b.payment_order)
             / (SELECT COUNT(*) FROM c), 2) AS cum_ltv_per_user
FROM prod.bi.base_data_for_ret_cancel b JOIN c USING (subscription_id)
WHERE b.transaction_type='BUY'
GROUP BY b.payment_order ORDER BY b.payment_order;

-- (2) Predicted next-12mo LTV by NPL cohort month
SELECT DATE_TRUNC('month', first_payment_dt) AS cohort_month,
       COUNT(*) AS n_npls,
       ROUND(AVG(adjusted_predicted_ltv), 2) AS avg_predicted_ltv
FROM prod.ml.user_level_ltv_prediction_npls_adj
WHERE first_payment_dt >= DATE'2025-12-01'
GROUP BY 1 ORDER BY 1;
```

---

## Out of scope — what this skill will NOT answer
The agent must **decline and route** (not guess) when a question falls outside the metrics and tables above. **Refuse rather than hallucinate a table, column, or number.** For **every** case below the routing is the same: **hand the requester to the Consumer Strategy DS team** (the owners of this skill) — a single front door. They triage and redirect to the owning function. Do not attempt the answer and do not bounce the requester between other teams.

- **Qualitative churn *reasons* / motivations** — these tables give churn/retention *rates* and decomposition (geo, product, promo mix), **not** *why* a learner or segment churned; no survey / NPS / sentiment / cancel-reason free-text lives here.
- **Data freshness / pipeline / ETL status** — "why is this table stale", "did the job run last night", backfill/lag questions are owned by Data Engineering; this skill only *states* the freshness caveat (last ~2 days incomplete; report through last complete month).
- **Payment failure / dunning / billing mechanics** — decline codes, retry/dunning logic, gateway errors, involuntary-vs-voluntary churn ops; the 7-day retry window is *assumed* (it drives the eligibility lag) but its mechanics are not analyzed here.
- **Individual learner data / PII** — no per-user lookups (who paid, email, account, payment method, personal progress); output is **aggregate only** (FERPA / GDPR / CCPA).
- **Enterprise (B2B) & Degrees metrics** — this skill is **B2C consumer only**; enterprise and degree users are excluded from every query.
- **Engagement & learning-outcome metrics** — D1/D7/W2/W4 engagement, M1 PER, learning hours, course/item completion *as an engagement metric* (s12n completion is used here **only** to split a "good" cancel from churn).
- **Marketing spend / CAC / ROAS** — TOF has visits and channel labels but **no spend/cost data**, so cost-per-acquisition and return-on-ad-spend cannot be computed here.
- **Forecasts, targets & financial planning** — the skill reports **actuals** plus the existing predicted-LTV *model output*; it does not generate new forecasts, budget/target attainment, or revenue-recognition / VAT / accounting treatment.
- **Causal / experiment readouts** — beyond the VMR rate-vs-mix decomposition, the skill does **not** attribute causation or read out A/B experiments.
- **Anything needing a table not documented above** — if the right table isn't in this file, **say so and stop**; do not invent a table or a column.

> **Routing:** all of the above go to **Consumer Strategy DS** for triage — one front door, not a hand-off chain between teams.
