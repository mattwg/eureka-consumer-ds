-- ============================================================================
-- Q2 2026 Tentpole Post-Mortem — Base Metrics (Intake row 2.1)
-- ============================================================================
-- Purpose: Cash + redemptions, split NPL vs Non-NPL, in totality and by campaign,
-- for the four Q2 post-mortem campaigns:
--   - Q1 C+ Monthly
--   - Q2 C+ Monthly
--   - March Tentpole 2026
--   - June Tentpole 2026
--
-- Source ask: DS Intake sheet (1CxqZdabaJdPdLPoQoz9E2idDJ4sB55-gr86-vw_o7tY), row 2.1.
-- Reused canonical join chain + filters from
--   skills/data-science/bizml/promotions/promo-metrics-lookup/references/.
--
-- Campaign definitions (promotion_id -> campaign) were derived empirically by
-- profiling prod.gold_base.completed_carts.promotion_name / promotion_id for
-- Jan-Jul 2026 and confirming with the requester. See campaign_map CTE below
-- for the exact promotion_ids in scope.
--
-- Held out / NOT yet included (pending confirmation, see promotion_id):
--   - 277443 "SEO discount page - 40% off 3 months of C+" — evergreen? unresolved.
--   - 277513 "XDP banner - 40% off 3 months of C+"        — evergreen? unresolved.
-- Confirmed excluded (evergreen, not campaign-specific):
--   - 278016 "40% off 3 months of C+ (Multi month) CRM"
--   - 249547 "March Affiliate Promo: 40% off Coursera Plus Annual" (runs Apr 2025-present)
-- Confirmed excluded (different promo type, not of interest to this analysis --
-- confirmed with requester 2026-07-14, see [[feedback-confirm-promo-scope-nuances]]):
--   - 286277 "US_2026_q2_cplusm__courseraplus" (previously included in Q2 C+ Monthly;
--     removed after explicit confirmation this is a different type of promo)
--
-- Corrections applied vs. a naive first pass (cross-checked against the pod's
-- existing "Daily Tracking Dashboard" reference query):
--   1. payment_order = 1 (or NULL) — a "redemption" is a subscription's FIRST
--      payment, not every recurring charge. Without this filter, Q1/Q2 C+ Monthly
--      redemptions/cash were ~2x inflated by renewal billing.
--   2. C+ Annual promo-SKU dual detection (product_item_id = 'GMM31Io6RjODN9SKOuYz_A')
--      — some tentpole redemptions apply the discount via SKU without populating
--      promotion_id. These are bucketed into a campaign by date window (not by ID,
--      since there is no promotion_id to map). Only applies to C Plus annual —
--      not a documented issue for C+ Monthly. The date window itself is derived
--      DYNAMICALLY (MIN/MAX(transaction_ts) for each campaign's promotion_ids, see
--      march_window/june_window CTEs) rather than hardcoded -- a hardcoded '2026-07-13'
--      end date for June Tentpole was initially assumed and went stale (real last
--      redemption was 7/14); dynamic derivation self-corrects instead of needing a
--      manual fix each time. See known-corrections.md for why we didn't add extra
--      robustness (e.g. requiring meaningful volume near the boundary) on top of
--      plain MIN/MAX -- kept intentionally simple per the requester's call.
--   3. 2-day late-arrival reconciliation trim (transaction_ts <= CURRENT_DATE - 2).
--      Also always quote the observed MIN/MAX(transaction_ts) alongside results (see
--      bottom of this file) so staleness is visible even though the window itself
--      is now self-correcting.
--
-- FinAid exclusion: not needed. None of the 17 campaign promotion_ids are FinAid
-- IDs (206409, 198078, 198074, 198077, 198513), and the SKU-fallback path only
-- fires when promotion_id IS NULL, which FinAid transactions never have.
--
-- Results as of 2026-07-16, using DYNAMICALLY-derived campaign windows (re-run
-- for current numbers -- window self-corrects, no manual date fix needed):
--   June Tentpole 2026 (TRUE final, window self-resolved to Jun 5 - Jul 14):
--     NPL 36,260 / $5,729,614 | Non-NPL 15,941 / $2,644,000 | Total 52,201 / $8,373,614
--     (up from the 2026-07-15 pull's 51,519/$8,239,038, which -- despite being
--     labeled "final" -- was still missing 7/14's data; see known-corrections.md
--     for the full story: a hardcoded end-date assumption of 7/13 went stale,
--     the true last redemption was 7/14, and the 2-day reconciliation trim
--     masked the gap until today)
--   March Tentpole 2026: NPL 26,357 / $5,131,255 | Non-NPL 11,995 / $2,383,210
--                         Total 38,352 / $7,514,466 (1-record drift from the
--                         7/15 pull -- negligible, likely a rare late correction
--                         to old data, not a query issue)
--   Q1 C+ Monthly: NPL 24,000 / $740,767 | Non-NPL 13,387 / $425,139 | Total 37,387 / $1,165,907
--   Q2 C+ Monthly (286277 excluded): NPL 18,297 / $489,506 | Non-NPL 8,783 / $246,934 | Total 27,080 / $736,440
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
-- Dynamically derived campaign windows (NOT hardcoded) -- used only by the
-- SKU-fallback CASE below, since promotion_id-based lookups need no date bound.
-- Self-corrects if a campaign's true last redemption lands later than expected
-- (see known-corrections.md for why this replaced a hardcoded date that went stale).
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
        ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id          -- BOTH keys, not just cart_id
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
    COUNT(DISTINCT transaction_id) AS redemptions,
    SUM(cash_receipt_usd_estimate) AS cash
FROM tagged
WHERE campaign IS NOT NULL
GROUP BY GROUPING SETS (
    (campaign, payer_type),
    ()
)
ORDER BY campaign, payer_type;

-- Always quote the observed min/max transaction date per campaign alongside
-- results (see known-corrections.md) -- run this alongside the query above:
-- SELECT 'March Tentpole 2026' AS campaign, * FROM march_window
-- UNION ALL
-- SELECT 'June Tentpole 2026' AS campaign, * FROM june_window
