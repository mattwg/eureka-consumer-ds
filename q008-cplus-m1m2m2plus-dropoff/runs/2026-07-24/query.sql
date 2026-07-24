-- q008: M1 / M2 / M2+ retention for C Plus monthly, and where the biggest drop-off is.
-- Method: canonical step renewal rate from consumer-ds-metrics-lookup
-- (metric-definitions.md "Retention rate" + common-queries.md section B).
-- Renewal signal = next_txn_stamp_sub_level (same subscription); 7-day eligibility lag.
-- Run read-only via Databricks MCP on 2026-07-24.

-- (0) VALIDATION — reproduce the documented Jan-2025 benchmark (M1 62.6 .. M5 79.5).
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

-- (1) ANSWER — M1 / M2 step retention (blended across all matured cohorts).
SELECT payment_order,
       COUNT(*)                                                 AS eligible_subs,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
  AND payment_order BETWEEN 1 AND 3
GROUP BY payment_order ORDER BY payment_order;

-- (2) ANSWER — M2+ (repeat renewals, payment_order >= 2, aggregate).
SELECT COUNT(*)                                                 AS eligible_subs,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS m2plus_renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
  AND payment_order >= 2;
