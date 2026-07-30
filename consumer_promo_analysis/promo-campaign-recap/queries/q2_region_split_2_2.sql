-- ============================================================================
-- Q2 2026 Tentpole Post-Mortem — Regional Split (Intake row 2.2)
-- ============================================================================
-- Purpose: Cash + redemptions by region, in totality and by campaign, for the
-- four Q2 post-mortem campaigns. Built on the same campaign_map + SKU-fallback
-- + payment_order + 2-day-trim fixes as q2_tentpole_base_metrics.sql -- see
-- that file for full rationale on those corrections (see known-corrections.md
-- for the current full list).
--
-- Region field: static_countries_vw.country_group_finance, joined via
-- users_vw.country_cd. NOTE: static_countries_vw's YAML doc (table-discovery/
-- promotions-tables) only documented country_cd/country_name -- it's flagged
-- "partial schema." Checked the live table schema and found three separate
-- grouping columns (country_group_finance, country_group_ds, country_group_pr)
-- with three different bucketing conventions. Picked country_group_finance
-- because it exactly matches the buckets the promo-metrics-lookup skill docs
-- reference (NAMER, EMEA, India, Non-India APAC, LatAm) -- country_group_ds is
-- a finer DS-specific sub-region breakdown, country_group_pr is a PR/comms
-- grouping. Do not swap without checking why.
--
-- Consistency check (run 2026-07-14): March Tentpole, Q1 C+ Monthly, and Q2
-- C+ Monthly totals here match q2_tentpole_base_metrics.sql EXACTLY (down to
-- the redemption). June Tentpole showed a small drift (+29 redemptions,
-- +$2,435, ~0.06%) vs. the base pull -- expected and NOT a query bug: June
-- Tentpole is the only campaign still inside the 2-day late-arrival
-- reconciliation window (ended 7/13, pulled 7/14), so a little more data
-- landed between the two query runs. Re-pull after reconciliation catches up
-- (any time after ~7/15) for the stable final number.
--
-- Each campaign has a small "(unmapped)" region bucket (11-186 redemptions
-- depending on campaign) -- country codes with no country_group_finance
-- match. Small enough relative to totals to not matter for reporting, but
-- not silently dropped either -- they show up as their own NULL-region row.
--
-- UPDATE 2026-07-14: removed promotion_id 286277 ("US_2026_q2_cplusm...")
-- from Q2 C+ Monthly -- confirmed with requester this is a different promo
-- type, not of interest to this analysis (see q2_tentpole_base_metrics.sql
-- and [[feedback-confirm-promo-scope-nuances]]). Q2 C+ Monthly numbers below
-- reflect ONLY promotion_id 285085 now; other 3 campaigns unaffected.
-- ============================================================================

WITH campaign_map AS (
    SELECT * FROM VALUES
        (277433, 'Q1 C+ Monthly'), (278227, 'Q1 C+ Monthly'), (278379, 'Q1 C+ Monthly'),
        (285085, 'Q2 C+ Monthly'),
        (279246, 'March Tentpole 2026'), (278665, 'March Tentpole 2026'), (281016, 'March Tentpole 2026'),
        (279263, 'March Tentpole 2026'), (283280, 'March Tentpole 2026'),
        (287775, 'June Tentpole 2026'), (287768, 'June Tentpole 2026'), (287767, 'June Tentpole 2026'),
        (287771, 'June Tentpole 2026'), (287769, 'June Tentpole 2026'), (290356, 'June Tentpole 2026'), (290357, 'June Tentpole 2026')
    AS t(promotion_id, campaign)
),
-- Dynamically derived campaign windows (NOT hardcoded) -- see
-- q2_tentpole_base_metrics.sql for why a hardcoded date went stale before.
march_window AS (
    SELECT MIN(DATE(ab.transaction_ts)) AS start_date, MAX(DATE(ab.transaction_ts)) AS end_date
    FROM prod.gold_base.transactions ab
    INNER JOIN prod.gold_base.completed_carts cc ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id
    WHERE cc.promotion_id IN (279246, 278665, 281016, 279263, 283280)
      AND ab.transaction_type = 'BUY' AND NOT ab.was_buy_transaction_refunded
      AND ab.transaction_business_line = 'B2C'
),
june_window AS (
    SELECT MIN(DATE(ab.transaction_ts)) AS start_date, MAX(DATE(ab.transaction_ts)) AS end_date
    FROM prod.gold_base.transactions ab
    INNER JOIN prod.gold_base.completed_carts cc ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id
    WHERE cc.promotion_id IN (287775, 287768, 287767, 287771, 287769, 290356, 290357)
      AND ab.transaction_type = 'BUY' AND NOT ab.was_buy_transaction_refunded
      AND ab.transaction_business_line = 'B2C'
),
tagged AS (
    SELECT
        ab.transaction_id,
        ab.transaction_ts,
        ab.cash_receipt_usd_estimate,
        scv.country_group_finance AS region,
        COALESCE(
            cm.campaign,
            CASE
                WHEN b1.product_sub_type = 'C Plus annual'
                     AND ab.product_item_id = 'GMM31Io6RjODN9SKOuYz_A'   -- C+ Annual promo SKU, dual detection
                     AND cc.promotion_id IS NULL
                     AND DATE(ab.transaction_ts) BETWEEN mw.start_date AND mw.end_date
                    THEN 'March Tentpole 2026'
                WHEN b1.product_sub_type = 'C Plus annual'
                     AND ab.product_item_id = 'GMM31Io6RjODN9SKOuYz_A'
                     AND cc.promotion_id IS NULL
                     AND DATE(ab.transaction_ts) BETWEEN jw.start_date AND jw.end_date
                    THEN 'June Tentpole 2026'
            END
        ) AS campaign
    FROM prod.gold_base.transactions ab
    CROSS JOIN march_window mw
    CROSS JOIN june_window jw
    INNER JOIN prod.gold_base.completed_carts cc
        ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id
    LEFT JOIN campaign_map cm
        ON cc.promotion_id = cm.promotion_id
    LEFT JOIN prod.bi.subscription_payments sp
        ON ab.user_id = sp.user_id AND ab.transaction_id = sp.transaction_id
    LEFT JOIN prod.bi.products_detail b1
        ON ab.product_item_id = b1.product_item_id AND ab.product_type = b1.product_type
    LEFT JOIN prod.gold.users_vw us1
        ON ab.user_id = us1.user_id
    LEFT JOIN prod.silver.static_countries_vw scv
        ON us1.country_cd = scv.country_cd
    WHERE ab.transaction_type = 'BUY'
      AND NOT ab.was_buy_transaction_refunded
      AND ab.transaction_business_line = 'B2C'
      AND (sp.payment_order = 1 OR sp.payment_order IS NULL)
      AND DATE(ab.transaction_ts) <= CURRENT_DATE - INTERVAL '2' DAYS
)
SELECT
    campaign,
    region,
    COUNT(DISTINCT transaction_id) AS redemptions,
    SUM(cash_receipt_usd_estimate) AS cash
FROM tagged
WHERE campaign IS NOT NULL
GROUP BY GROUPING SETS (
    (campaign, region),
    (campaign)
)
ORDER BY campaign, region;

-- ============================================================================
-- Results as of 2026-07-16 (for reference -- re-run for current numbers):
--
-- June Tentpole 2026 (window now DYNAMICALLY derived -- observed Jun 5 to Jul 14;
-- see q2_tentpole_base_metrics.sql for why this replaced a hardcoded, and once
-- stale, end date). Total 52,201 / $8,373,614:
--                       NAMER 17,098 / $3,667,873  | EMEA 12,334 / $2,193,760
--                       India 12,157 / $961,335     | Non-India APAC 5,779 / $860,649
--                       LatAm 4,822 / $687,959      | unmapped 11 / $2,038
-- March Tentpole 2026:  NAMER 15,977 / $3,765,163  | EMEA 10,024 / $2,050,416
--                       India 4,329 / $381,264      | LatAm 4,083 / $634,479
--                       Non-India APAC 3,931 / $681,337 | unmapped 9 / $1,961
-- Q1 C+ Monthly:        NAMER 15,797 / $555,938    | EMEA 12,398 / $378,192
--                       Non-India APAC 4,616 / $122,303 | LatAm 4,308 / $100,518
--                       India 82 / $2,788           | unmapped 186 / $6,168
-- Q2 C+ Monthly (updated 2026-07-14, 286277 excluded):
--                       NAMER 13,400 / $470,362     | EMEA 4,290 / $76,816
--                       LatAm 5,693 / $123,887       | Non-India APAC 3,588 / $62,096
--                       India 31 / $944              | unmapped 77 / $2,292
--
-- Notable pattern: India is a tiny share of C+ Monthly redemptions (82, 47)
-- vs. thousands for the tentpoles -- worth keeping in mind given India's
-- high price sensitivity and the geo-pricing/India-subscriptions product
-- test context from the WIP items excluded from this analysis's scope.
-- ============================================================================
