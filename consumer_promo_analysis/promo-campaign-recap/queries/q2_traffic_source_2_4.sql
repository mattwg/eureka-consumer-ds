-- ============================================================================
-- Q2 2026 Tentpole Post-Mortem — Traffic Source Split (Intake row 2.4)
-- ============================================================================
-- Purpose: Cash + redemptions, split NPL vs Non-NPL and by channel, in
-- totality and by campaign, for the four Q2 post-mortem campaigns.
-- Built on the same campaign_map + SKU-fallback + payment_order fixes as
-- q2_tentpole_base_metrics.sql -- see that file for full rationale on those
-- corrections (payment_order=1, C+ Annual SKU dual detection, 2-day
-- late-arrival trim; see known-corrections.md for the current full list).
--
-- What "channel" means here (IMPORTANT CAVEAT):
-- channel = us.first_payment_referrer_cons_l0_mktg_chnl_ft28d, from
-- prod.gold.user_stats_vw -- a pre-built "Conservative Level 0 marketing
-- channel" attribution field (28-day first-touch lookback), already
-- available via the user_stats_vw join we use for the NPL flag. Found via
-- cross-checking a reference query shared by the requester (see note below
-- on a bug in that reference query).
--
-- This field is keyed to the user's FIRST PAYMENT EVER, not to this specific
-- redemption:
--   - For NPL redemptions: this transaction IS the user's first payment, so
--     "channel" cleanly means "what drove this redemption."
--   - For Non-NPL redemptions (renewal/reactivation): "channel" reflects
--     whatever drove the user's ORIGINAL signup, possibly years earlier --
--     NOT necessarily what brought them back for this specific promo.
--   Included for both payer types per requester's call, but read Non-NPL
--   channel as "original acquisition channel of this redeemer," not "what
--   drove this redemption."
--
-- GRANULARITY NOTE: Level 0 is only a binary -- Organic vs. Paid. The 2.4
-- ask wanted finer detail ("paid, seo, email, etc"), which requires L1-L4
-- (also on user_stats_vw: first_payment_referrer_cons_l1_mktg_chnl_ft28d
-- through _l4_). Not yet investigated -- revisit if finer-than-Organic/Paid
-- detail is needed.
--
-- Bug found in a reference query shared during this analysis (different
-- purpose -- a "Google AI" course-completion x promo channel dive, table
-- dev.general.cplus_40_q2_dive_v0): it checks
-- `ab.underlying_product_item_id = 'GMM31Io6RjODN9SKOuYz_A'` for the C+
-- Annual promo SKU dual-detection. Verified empirically: that SKU value
-- matches 5,888 rows on `product_item_id` (March Tentpole window) and ZERO
-- rows on `underlying_product_item_id`. product_item_id is "the purchasable
-- product" (what a SKU is); underlying_product_item_id is "the educational
-- product" (course/specialization ID) -- different concepts per the table's
-- own column docs. That query's promo flag never fires via the SKU path.
-- Our query (below) correctly uses `product_item_id`.
--
-- Small `(null)` channel bucket appears on Q1/Q2 C+ Monthly Non-NPL (53, 45
-- redemptions at time of original run) -- likely users predating this
-- attribution tracking. Small enough to not matter for reporting.
--
-- UPDATE 2026-07-14: removed promotion_id 286277 ("US_2026_q2_cplusm...")
-- from Q2 C+ Monthly -- confirmed with requester this is a different promo
-- type, not of interest to this analysis (see q2_tentpole_base_metrics.sql
-- and [[feedback-confirm-promo-scope-nuances]]). Updated Q2 C+ Monthly
-- numbers: NPL Organic 8,395 / $224,890, NPL Paid 9,903 / $264,630,
-- Non-NPL Organic 5,891 / $168,223, Non-NPL Paid 2,848 / $77,769,
-- Non-NPL (null channel) 42 / $887. Other 3 campaigns unaffected.
--
-- UPDATE 2026-07-16: June Tentpole 2026 re-pulled with the dynamically-derived
-- window (TRUE final, correcting a stale hardcoded 7/13 end date -- see
-- known-corrections.md): NPL Organic 17,567 / $2,863,924, NPL Paid 18,693 /
-- $2,865,690, Non-NPL Organic 11,282 / $1,902,980, Non-NPL Paid 4,659 /
-- $741,020. Total 52,201, matches final base metrics exactly. (Up from the
-- 2026-07-15 pull's 51,519 total, which was still missing 7/14's data.)
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
-- Safe here (no Amplitude join in this file) -- see known-corrections.md for
-- why the dynamic-CTE approach is fine for transactions-only queries but NOT
-- for Amplitude-joined ones (partition pruning issue).
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
        us.first_unrefund_payment_ts,
        -- see header note on what "channel" means and its Non-NPL caveat
        us.first_payment_referrer_cons_l0_mktg_chnl_ft28d AS channel,
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
    LEFT JOIN prod.gold.user_stats_vw us
        ON ab.user_id = us.user_id
    WHERE ab.transaction_type = 'BUY'
      AND NOT ab.was_buy_transaction_refunded
      AND ab.transaction_business_line = 'B2C'
      AND (sp.payment_order = 1 OR sp.payment_order IS NULL)
      AND DATE(ab.transaction_ts) <= CURRENT_DATE - INTERVAL '2' DAYS
)
SELECT
    campaign,
    CASE WHEN transaction_ts = first_unrefund_payment_ts THEN 'NPL' ELSE 'Non-NPL' END AS payer_type,
    channel,
    COUNT(DISTINCT transaction_id) AS redemptions,
    SUM(cash_receipt_usd_estimate) AS cash
FROM tagged
WHERE campaign IS NOT NULL
GROUP BY GROUPING SETS (
    (campaign, payer_type, channel),
    (campaign)
)
ORDER BY campaign, payer_type, channel;
