-- Query 9: Country-level transactions split, Test vs Control.
-- Part of the "country level breakdown at the traffic split and transactions
-- split — focussed on top 5 countries" nuance from SKILL.md Section 2.
-- Date window here is the full promo (2026-06-08 to 2026-07-13), not the
-- test-end-capped window used in Queries 6/7.

with domain as (
    select distinct
        coalesce(c.course_slug,ps.phoenix_specialization_slug) as product_slug
        ,upp.underlying_product_item_id
        ,coalesce(course_primary_domain,phoenix_specialization_primary_domain) as primary_domain
    from prod.bi.underlying_products_partners upp
    left join prod.gold.courses_vw c
        on c.course_id = upp.underlying_product_item_id
    left join prod.gold.phoenix_specializations_vw ps
        on ps.phoenix_specialization_id = upp.underlying_product_item_id
),
high_pricing_test_users AS (
      WITH variants AS (
      SELECT
        -- Experiment metadata.
        epic_experiment_id
        , epic_experiment_started_at
        , epic_experiment_ended_ts
        , MAX(COALESCE(epic_experiment_ended_ts, CURRENT_DATE)) OVER () AS end_ts
        , epic_experiment_display_name
        -- Variant metadata.
        , epic_variant_id
        , epic_variant_weight
        , TRIM(epic_variant_name) AS cleaned_epic_variant_name
        ,
        (MAX(CASE WHEN epic_variant_index = 0 AND epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w' THEN 1 ELSE 0 END)
        OVER (PARTITION BY TRIM(epic_variant_name)))::BOOLEAN
         AS is_control
        -- Get the order of variants. Order same as EPIC unless control is manually set, in which case control is put first.
        , CASE
        WHEN is_control THEN 1
        ELSE -MIN(epic_variant_index) OVER (PARTITION BY TRIM(epic_variant_name))
        END AS sort_by
      FROM prod.bi.epic_variants
      JOIN prod.bi.epic_experiments USING (epic_experiment_id)
      WHERE (
      epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w'

      )
      AND epic_experiment_allocation_type = 'BY_USER'
      )

      SELECT
         is_control
        , user_id
        -- Get impression start and end timestamps for metrics calculations. This includes users
        , MIN(impression_ts) AS start_ts,
          MAX(end_ts) AS end_ts
      FROM prod.bi.epic_user_impressions
      JOIN variants USING (epic_experiment_id, epic_variant_id)
      WHERE
        impression_dt BETWEEN epic_experiment_started_at::DATE AND COALESCE(epic_experiment_ended_ts::DATE, CURRENT_DATE) -- speeds up the computation
        AND impression_ts BETWEEN epic_experiment_started_at AND COALESCE(epic_experiment_ended_ts, CURRENT_DATE)
        AND 1=1 -- no filter on 'impressions.impression_date'

      GROUP BY 1, 2),
 base AS (
  SELECT * FROM (
SELECT
    CAST(COALESCE(CAST(hpt.is_control AS STRING),'non-high_pricing_test_population') AS STRING) AS hpt_flag,
    ab.*,
    hpt.start_ts AS hpt_start_ts,
    hpt.end_ts AS hpt_end_ts,
    b.country_group_finance,
    us.first_payment_referrer_cons_l0_mktg_chnl_ft28d as channel,
    COALESCE(b1.product_sub_type, ab.underlying_product_type) AS product_sub_type,
    d.is_cplus_upsell,
    DATE(ab.transaction_ts) AS transaction_dt,
    a.payment_order,
    recurring_payment_start_ts,
    recurring_payment_end_ts,
    a.subscription_id,
    a.subscription_status,
    a.is_subscription_active,
    cc1.promotion_name,
    cc1.promotion_id,
    CASE WHEN cc1.promotion_id IN (287767, 287768, 287769, 287771, 287775) THEN 1 ELSE 0 END AS Q2_2026_Tentpole_promo_flag,
    subscription_cancel_ts,
    subscription_inactivation_ts,
    f.country_cd,
    CASE
        WHEN primary_domain IS NULL THEN 'Others'
        ELSE primary_domain
    END AS primary_domain,
    COALESCE(subscription_cancel_ts, subscription_inactivation_ts) AS subscription_end_ts,
    ROW_NUMBER() OVER (PARTITION BY ab.transaction_id ORDER BY ab.transaction_ts ASC) AS rn1
FROM prod.gold.transactions_vw ab
LEFT JOIN prod.gold.completed_carts_vw cc1
    ON ab.user_id = cc1.user_id
    AND ab.cart_id = cc1.cart_id
LEFT JOIN prod.gold.users_vw f
    ON ab.user_id = f.user_id
LEFT JOIN prod.silver_base.static_countries b
    ON f.country_cd = b.country_cd
LEFT JOIN prod.bi.subscription_payments a
    ON a.user_id = ab.user_id
    AND a.transaction_id = ab.transaction_id
LEFT JOIN prod.bi.subscriptions__payment_stats d
    ON a.user_id = d.user_id
    AND a.subscription_id = d.subscription_id
LEFT JOIN domain pt
    ON a.underlying_product_item_id = pt.underlying_product_item_id
LEFT JOIN prod.bi.products_detail b1
    ON ab.product_item_id = b1.product_item_id
    AND ab.product_type = b1.product_type
LEFT JOIN high_pricing_test_users hpt ON ab.user_id = hpt.user_id AND ab.transaction_ts between hpt.start_ts AND hpt.end_ts
LEFT JOIN prod.gold.user_stats_vw us ON ab.user_id=us.user_id
WHERE transaction_type = 'BUY'
    AND NOT was_buy_transaction_refunded
    AND transaction_business_line = 'B2C'
    AND DATE(ab.transaction_ts) <= (CAST(DATE_FORMAT(CAST('2026-07-13' AS DATE), 'yyyy-MM-dd') AS DATE))
    AND DATE(ab.transaction_ts) >= (CAST(DATE_FORMAT(CAST('2026-06-08' AS DATE), 'yyyy-MM-dd') AS DATE)))
    WHERE rn1=1
),
cplus_annual AS (
  SELECT *
  FROM base
  WHERE product_sub_type = 'C Plus annual'
    AND hpt_flag IN ('true', 'false')      -- experiment population only
)
SELECT
  CASE WHEN hpt_flag = 'true' THEN 'Control' ELSE 'Test' END AS arm,
  CASE
    WHEN transaction_dt < DATE'2026-06-08' THEN 'Pre-promo'
--    WHEN transaction_dt BETWEEN DATE'2026-06-08' AND DATE'2026-06-17' THEN 'During early bird'
    ELSE 'Promo'
  END AS period,
  country_cd,
  -- Users
  COUNT(DISTINCT CASE WHEN Q2_2026_Tentpole_promo_flag = 1 THEN user_id END) AS promo_users
FROM cplus_annual
GROUP BY 1, 2, 3
ORDER BY arm, MIN(transaction_dt);
