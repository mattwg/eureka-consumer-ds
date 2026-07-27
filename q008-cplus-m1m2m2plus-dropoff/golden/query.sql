-- Golden reference query for q008 (proposed). Proof the method runs and returns the
-- right shape. Method-only: the numbers below will drift with data; the METHOD is frozen.

-- M1 / M2 step retention, C Plus monthly, all matured cohorts.
SELECT payment_order,
       COUNT(*)                                                 AS eligible_subs,
       ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
  AND payment_order BETWEEN 1 AND 2
GROUP BY payment_order ORDER BY payment_order;

-- M2+ (repeat renewals, payment_order >= 2, aggregate).
SELECT ROUND(COUNT(next_txn_stamp_sub_level)*100.0/COUNT(*), 1) AS m2plus_renewal_pct
FROM prod.bi.base_data_for_ret_cancel
WHERE transaction_business_line='B2C' AND transaction_type='BUY'
  AND product_sub_type='C Plus monthly' AND was_buy_transaction_refunded=FALSE
  AND recurring_payment_end_ts < CURRENT_DATE()-INTERVAL 7 DAYS
  AND payment_order >= 2;
