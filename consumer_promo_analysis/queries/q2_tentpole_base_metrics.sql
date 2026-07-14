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
--      not a documented issue for C+ Monthly.
--   3. 2-day late-arrival reconciliation trim (transaction_ts <= CURRENT_DATE - 2).
--      CAVEAT: as of 2026-07-14, this trims June Tentpole's own last 2 days
--      (7/12-7/13, the campaign's actual final days), since the tentpole ended
--      7/13. June Tentpole numbers from this query are PROVISIONAL until
--      re-run after reconciliation catches up (re-run any time after ~7/15).
--
-- FinAid exclusion: not needed. None of the 17 campaign promotion_ids are FinAid
-- IDs (206409, 198078, 198074, 198077, 198513), and the SKU-fallback path only
-- fires when promotion_id IS NULL, which FinAid transactions never have.
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
                     AND DATE(ab.transaction_ts) BETWEEN '2026-03-24' AND '2026-04-29'
                    THEN 'March Tentpole 2026'
                WHEN b1.product_sub_type = 'C Plus annual'
                     AND ab.product_item_id = 'GMM31Io6RjODN9SKOuYz_A'
                     AND cc.promotion_id IS NULL
                     AND DATE(ab.transaction_ts) BETWEEN '2026-06-05' AND '2026-07-13'
                    THEN 'June Tentpole 2026'
            END
        ) AS campaign
    FROM prod.gold_base.transactions ab
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
