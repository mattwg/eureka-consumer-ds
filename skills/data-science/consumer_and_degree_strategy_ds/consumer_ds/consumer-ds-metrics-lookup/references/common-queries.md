# consumer_ds — Common Queries (worked, verified patterns)

One runnable query per question-shape in `questions.md`. Every block below was **run live against
Databricks**. Swap the date / product / segment literals for the ask. See `metric-definitions.md`
for the full caveats behind each. Default to the **last complete month** and **all product sub
types** unless the user specifies otherwise.

Shared facts: B2C base table holds only non-refunded BUYs (`cash ≡ amount`); renewal signal is
`next_txn_stamp_sub_level`; TOF `new_visits` is all-audience (never group by `user_segment`);
NRL/NPL require `user_segment='B2C'`.

---

## A. Headline KPIs — last complete month, by region
```sql
-- Cash + Total Payers (base_data)
SELECT country_group_finance,
       ROUND(SUM(cash_receipt_usd_estimate)) AS net_cash_usd,
       COUNT(DISTINCT user_id)               AS total_payers
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY' AND was_buy_transaction_refunded=FALSE
  AND DATE_TRUNC('month', transaction_dt)=DATE'2026-05-01'
GROUP BY 1 ORDER BY net_cash_usd DESC;
-- Total Payers grand total: COUNT(DISTINCT user_id) with no GROUP BY (don't sum regions).
```
```sql
-- NRL, NPL, New Visits, Total Visits (TOF) — one month
SELECT
  SUM(CASE WHEN user_segment='B2C' THEN nrls END)                                          AS nrls_consumer,
  SUM(CASE WHEN user_segment='B2C' AND user_finaid_status<>'FINAID_user' THEN npls END)    AS npls_consumer_exfinaid,
  SUM(new_visits) AS new_visits,
  SUM(visits)     AS total_visits
FROM prod.bi.tof_consolidated_tracking_table
WHERE DATE_TRUNC('month', event_dt)=DATE'2026-05-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'));
```
*MTD / YoY:* swap the month filter to a `DAY(transaction_dt) <= DAY(CURRENT_DATE())` window and
compare to the same span in the prior month / prior year.

---

## B. Step retention — M1 / M2 / M2+ (where's the drop-off?)
```sql
SELECT payment_order,
       COUNT(*)                                                  AS eligible_subs,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1)  AS renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
  AND DATE_TRUNC('month', transaction_dt)=DATE'2025-01-01'
  AND payment_order BETWEEN 1 AND 5
GROUP BY payment_order ORDER BY payment_order;
-- M2+ (repeat renewals): same filters with payment_order >= 2, no GROUP BY.
-- Verified benchmark (C+ monthly, Jan-2025): M1 62.6 → M2 67.8 → M3 74.8 → M4 78.5 → M5 79.5.
```

## C. Full 12-month survival curve (single cohort, + YoY)
```sql
WITH cohort AS (
  SELECT subscription_id FROM prod.bi.base_data_for_ret_cancel
  WHERE transaction_business_line='B2C' AND transaction_type='BUY'
    AND product_sub_type='C Plus monthly' AND payment_order=1 AND was_buy_transaction_refunded=FALSE
    AND DATE_TRUNC('month', transaction_dt)=DATE'2026-01-01'   -- cohort month
)
SELECT b.payment_order,
       ROUND(COUNT(DISTINCT b.subscription_id)*100.0/(SELECT COUNT(*) FROM cohort), 1) AS pct_surviving
FROM prod.bi.base_data_for_ret_cancel b JOIN cohort USING (subscription_id)
WHERE b.transaction_type='BUY' AND b.payment_order BETWEEN 1 AND 12
GROUP BY b.payment_order ORDER BY b.payment_order;
-- YoY: run again with the Jan-2025 cohort and place the two curves side by side.
-- Curve is cumulative survival (PO1=100%); the conditional step rate in (B) is a different cut.
```

## D. Promo / upsell / full-price retention split
```sql
SELECT CASE
         WHEN promotion_name ILIKE '%40% off 3 months of C+%'
           OR promotion_name='global_2026_q2_cplusm__courseraplus_xpp_40_p____google' THEN '40pct_promo'
         WHEN is_cplus_upsell THEN 'upsell'
         ELSE 'full_price' END                                  AS segment,
       payment_order,
       COUNT(*)                                                 AS eligible_subs,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
GROUP BY 1,2 ORDER BY 1,2;
-- Watch the M3→M4 price-shock cliff for 40pct_promo (the discount ends after 3 months —
-- the segment has no payment_order 4 because those rows are no longer promo-priced).
```

## E. Monthly vs annual, first vs repeat renewal
```sql
SELECT product_sub_type,
       CASE WHEN payment_order=1 THEN 'M1 (first renewal)' ELSE 'M2+ (repeat)' END AS step,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS renewal_pct,
       COUNT(*) AS eligible_subs
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY' AND was_buy_transaction_refunded=FALSE
  AND product_sub_type IN ('C Plus monthly','C Plus annual')
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
GROUP BY 1,2 ORDER BY 1,2;
-- Annual cohorts need 13+ months maturity before the eligibility lag is meaningful.
```

## F. Channel cuts — NPL by channel & New-Visit→NPL conversion
```sql
-- NPL by marketing channel (Consumer, last complete month)
SELECT referrer_cons_l1_mktg_chnl, SUM(npls) AS npls
FROM prod.bi.tof_consolidated_tracking_table
WHERE user_segment='B2C' AND user_finaid_status<>'FINAID_user'
  AND DATE_TRUNC('month', event_dt)=DATE'2026-05-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'))
GROUP BY 1 ORDER BY 2 DESC;
```
```sql
-- New-Visit → NPL conversion by channel (all-audience denominator; see grain note)
SELECT referrer_cons_l1_mktg_chnl,
       SUM(new_visits) AS new_visits, SUM(npls) AS npls,
       ROUND(SUM(npls)*100.0/NULLIF(SUM(new_visits),0), 4) AS nv_to_npl_pct
FROM prod.bi.tof_consolidated_tracking_table
WHERE DATE_TRUNC('month', event_dt)=DATE'2026-05-01'
  AND NOT ((referrer_cons_l1_mktg_chnl='Direct' AND country_cd='CN')
        OR (referrer_cons_l2_mktg_chnl IN ('E2C') AND country_cd='SG'))
GROUP BY 1 ORDER BY new_visits DESC;
-- Do NOT add user_segment='B2C' (new_visits collapses to 0). Numerator can be all-audience npls
-- (default) or B2C-only — document which; see metric-definitions.md.
```

## G. 14-day registration → paid conversion (by device/geo)
```sql
WITH regs AS (
  SELECT u.user_id, u.registration_ts, u.registration_os_l1
  FROM prod.gold.users_vw u
  LEFT ANTI JOIN prod.gold.enterprise_contract_program_memberships_vw e ON u.user_id=e.user_id
  LEFT ANTI JOIN prod.gold_base.degree_course_session_enrollments     d ON u.user_id=d.user_id
  WHERE DATE_TRUNC('month', u.registration_ts)=DATE'2026-04-01'   -- cohort ≥14 days matured
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
-- Add GROUP BY registration_os_l1 (device) or join static_countries_vw for geo. Runs low single-digit %.
```

## H. Completion-driven cancel vs true churn (cert/spec terminal subs)
```sql
WITH ended_subs AS (
  SELECT subscription_id, user_id, underlying_product_item_id AS phoenix_specialization_id,
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
-- Extend product_sub_type IN ('Specialization monthly','Gateway Certificate monthly','Professional Certificate monthly').
-- Verified Mar-2026 Specialization monthly: ~21% completion-driven / ~79% true churn. NOT for C+ (all-access).
```

## I. LTV — cohort (actual) and predicted
```sql
-- Cohort LTV/user (cumulative revenue per original subscriber)
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
```
```sql
-- Predicted next-12-mo LTV by NPL cohort month (table is already NPL-scoped)
SELECT DATE_TRUNC('month', first_payment_dt) AS cohort_month,
       COUNT(*) AS n_npls, ROUND(AVG(adjusted_predicted_ltv), 2) AS avg_predicted_ltv
FROM prod.ml.user_level_ltv_prediction_npls_adj
WHERE first_payment_dt >= DATE'2025-12-01'
GROUP BY 1 ORDER BY 1;
-- For a pure-B2C number, LEFT ANTI JOIN the enterprise + degree exclusion tables.
```

## J. Rate vs mix — YoY decomposition by region / product
"Decompose the YoY change in retention by region (or product sub type) into rate vs mix" is a
**volume-mix-rate (VMR) decomposition**, not a single query — hand it to the pod's **VMR
decomposition** workflow. Feed it the metric (e.g. blended renewal rate), the two periods, and the
dimension (region / product sub type). The per-segment rates come from query (B)/(E) above; VMR
splits the headline change into how much is genuine rate movement vs mix shift between segments.
