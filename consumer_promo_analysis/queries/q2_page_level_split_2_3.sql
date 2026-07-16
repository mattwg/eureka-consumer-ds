-- ============================================================================
-- Q2 2026 Tentpole Post-Mortem — Page-Level Split (Intake row 2.3) -- FINAL
-- ============================================================================
-- Purpose: Redemptions + cash by page type, in totality and by campaign, for
-- the four Q2 post-mortem campaigns. Built on the same campaign definitions
-- as q2_tentpole_base_metrics.sql (payment_order=1, C+ Annual SKU dual
-- detection, 2-day late-arrival trim, 286277 excluded from Q2 C+ Monthly --
-- see that file for full rationale).
--
-- Methodology: for each redeemer, look at Amplitude events in the 7 days
-- before their redemption -- either a ViewMerchandisingModule event (gives
-- page.type) or, as fallback, a ViewPage on the C+ page (tagged "C+ Page").
-- Take whichever happened FIRST in that window (first-touch); if neither
-- exists, tag "Direct / No Attribution". Adapted from a reference query
-- shared during this analysis -- see git history / prior conversation for
-- the original and the bug found in it (wrong column for SKU dual-detection:
-- `underlying_product_item_id` instead of `product_item_id`).
--
-- Resolution of the three original open items:
--   1. Redeemer definition -- FIXED. Uses our own campaign_map + SKU-fallback
--      (below), not the reference query's broad ILIKE pattern. Verified: each
--      campaign's page-type breakdown sums to match its known total exactly
--      (Q1: 37,387; Q2: 27,079; March: 38,353), except June Tentpole which is
--      off by ~4 redemptions from the base pull -- expected, same reconciliation-
--      lag drift documented in q2_tentpole_base_metrics.sql (June is still
--      inside the 2-day late-arrival window).
--   2. Hardcoded campaign-name restriction -- FIXED. Query takes whatever
--      page.type shows up per redeemer; does not filter by
--      merchandisingModule.campaign.name at all. Confirmed real names differ
--      from what we might have assumed (e.g. March Tentpole's actual Amplitude
--      campaign name is "2026 March Q1 Spring Tentpole", not "March Tentpole
--      2026" -- that's just our transaction-side label).
--   3. Tentpole coverage gap -- RESOLVED. Confirmed empirically: the same
--      ViewMerchandisingModule/page.type tracking exists for both C+ Annual
--      tentpoles, with an overlapping page-type vocabulary to C+ Monthly
--      (xdp_course, xdp_professional_cert, xdp_s12n, lohp, lihp, browse,
--      xdp_paid_media, xdp_project) plus a couple of Annual-specific ones
--      (cplus_description, promo_template, search_result_page).
--
-- PERFORMANCE NOTE (two-step process required for the Amplitude join): a
-- single query joining all 4 campaigns' redeemers to Amplitude in one UNION
-- ALL did not complete even after ~10 minutes. Running one campaign at a
-- time (tight event_date bound = campaign window + 7-day lookback) completed
-- in under a minute each -- but ONLY when that bound is a LITERAL date, not
-- a value derived from a CTE/subquery in the same query. Databricks appears
-- unable to use a runtime-computed bound for partition pruning on
-- `event_date`, so embedding `(SELECT end_date FROM june_window)` directly in
-- this query's WHERE clause reintroduced the same 10+ minute non-completion,
-- even though the window CTE itself resolves fast. See known-corrections.md.
--
-- REQUIRED PROCESS when re-running the March/June blocks below:
--   Step 1 (fast, seconds): resolve the current window --
--     SELECT MIN(DATE(ab.transaction_ts)) AS start_date, MAX(DATE(ab.transaction_ts)) AS end_date
--     FROM prod.gold_base.transactions ab
--     INNER JOIN prod.gold_base.completed_carts cc ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id
--     WHERE cc.promotion_id IN (<campaign's promotion_ids, per campaign_map>)
--       AND ab.transaction_type = 'BUY' AND NOT ab.was_buy_transaction_refunded
--       AND ab.transaction_business_line = 'B2C'
--   Step 2: paste the resulting start_date/end_date as LITERALS into the
--     March/June `impressions` blocks' `event_date BETWEEN ...` bound below
--     (start_date minus 7 days for the lookback buffer) before running.
-- The `redeemers` CTE's own dynamic march_window/june_window (used for the
-- SKU-fallback campaign tagging) is fine as-is -- it only touches
-- transactions/completed_carts, never Amplitude, so it doesn't hit this
-- partition-pruning issue.
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
redeemers AS (
    SELECT
        ab.transaction_id, ab.user_id, ab.transaction_ts, ab.cash_receipt_usd_estimate,
        COALESCE(
            cm.campaign,
            CASE
                WHEN b1.product_sub_type = 'C Plus annual'
                     AND ab.product_item_id = 'GMM31Io6RjODN9SKOuYz_A'
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
    LEFT JOIN campaign_map cm ON cc.promotion_id = cm.promotion_id
    LEFT JOIN prod.bi.subscription_payments sp
        ON ab.user_id = sp.user_id AND ab.transaction_id = sp.transaction_id
    LEFT JOIN prod.bi.products_detail b1
        ON ab.product_item_id = b1.product_item_id AND ab.product_type = b1.product_type
    WHERE ab.transaction_type = 'BUY'
      AND NOT ab.was_buy_transaction_refunded
      AND ab.transaction_business_line = 'B2C'
      AND (sp.payment_order = 1 OR sp.payment_order IS NULL)
      AND DATE(ab.transaction_ts) <= CURRENT_DATE - INTERVAL '2' DAYS
),
impressions AS (
    SELECT r.transaction_id, r.campaign, ae.client_event_time,
           COALESCE(ae.event_properties.`page.type`, 'C+ Page') AS page_type
    FROM redeemers r
    INNER JOIN prod.silver.consolidated_amplitude_v3_events_vw ae
        ON CAST(ae.attributed_user_id AS BIGINT) = r.user_id
        AND ae.client_event_time <= r.transaction_ts
        AND ae.client_event_time >= r.transaction_ts - INTERVAL 7 DAYS
    WHERE r.campaign = 'Q1 C+ Monthly'
      AND ae.event_date BETWEEN '2026-02-06' AND '2026-05-20'
      AND (ae.event_type = 'ViewMerchandisingModule'
           OR (ae.event_type = 'ViewPage' AND ae.event_properties.`page.url` ILIKE 'https://www.coursera.org/courseraplus%'))

    UNION ALL
    SELECT r.transaction_id, r.campaign, ae.client_event_time,
           COALESCE(ae.event_properties.`page.type`, 'C+ Page') AS page_type
    FROM redeemers r
    INNER JOIN prod.silver.consolidated_amplitude_v3_events_vw ae
        ON CAST(ae.attributed_user_id AS BIGINT) = r.user_id
        AND ae.client_event_time <= r.transaction_ts
        AND ae.client_event_time >= r.transaction_ts - INTERVAL 7 DAYS
    WHERE r.campaign = 'Q2 C+ Monthly'
      AND ae.event_date BETWEEN '2026-04-21' AND '2026-07-12'
      AND (ae.event_type = 'ViewMerchandisingModule'
           OR (ae.event_type = 'ViewPage' AND ae.event_properties.`page.url` ILIKE 'https://www.coursera.org/courseraplus%'))

    UNION ALL
    SELECT r.transaction_id, r.campaign, ae.client_event_time,
           COALESCE(ae.event_properties.`page.type`, 'C+ Page') AS page_type
    FROM redeemers r
    INNER JOIN prod.silver.consolidated_amplitude_v3_events_vw ae
        ON CAST(ae.attributed_user_id AS BIGINT) = r.user_id
        AND ae.client_event_time <= r.transaction_ts
        AND ae.client_event_time >= r.transaction_ts - INTERVAL 7 DAYS
    WHERE r.campaign = 'March Tentpole 2026'
      -- LITERAL dates, resolved via the Step 1 query in the header note above
      -- (last resolved 2026-07-16: start_date=2026-03-24, end_date=2026-04-29)
      AND ae.event_date BETWEEN '2026-03-17' AND '2026-04-29'
      AND (ae.event_type = 'ViewMerchandisingModule'
           OR (ae.event_type = 'ViewPage' AND ae.event_properties.`page.url` ILIKE 'https://www.coursera.org/courseraplus%'))

    UNION ALL
    SELECT r.transaction_id, r.campaign, ae.client_event_time,
           COALESCE(ae.event_properties.`page.type`, 'C+ Page') AS page_type
    FROM redeemers r
    INNER JOIN prod.silver.consolidated_amplitude_v3_events_vw ae
        ON CAST(ae.attributed_user_id AS BIGINT) = r.user_id
        AND ae.client_event_time <= r.transaction_ts
        AND ae.client_event_time >= r.transaction_ts - INTERVAL 7 DAYS
    WHERE r.campaign = 'June Tentpole 2026'
      -- LITERAL dates, resolved via the Step 1 query in the header note above
      -- (last resolved 2026-07-16: start_date=2026-06-05, end_date=2026-07-14)
      AND ae.event_date BETWEEN '2026-05-29' AND '2026-07-14'
      AND (ae.event_type = 'ViewMerchandisingModule'
           OR (ae.event_type = 'ViewPage' AND ae.event_properties.`page.url` ILIKE 'https://www.coursera.org/courseraplus%'))
),
first_touch AS (
    SELECT transaction_id, page_type
    FROM (
        SELECT transaction_id, page_type,
               ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY client_event_time ASC) AS rn
        FROM impressions
    ) WHERE rn = 1
)
SELECT
    r.campaign,
    COALESCE(ft.page_type, 'Direct / No Attribution') AS page_type,
    COUNT(DISTINCT r.transaction_id) AS redemptions,
    SUM(r.cash_receipt_usd_estimate) AS cash
FROM redeemers r
LEFT JOIN first_touch ft ON r.transaction_id = ft.transaction_id
WHERE r.campaign IS NOT NULL
GROUP BY r.campaign, page_type
ORDER BY r.campaign, redemptions DESC;

-- ============================================================================
-- Results as of 2026-07-14 (for reference -- re-run for current numbers,
-- especially June Tentpole which was still reconciling):
--
-- Q1 C+ Monthly (total 37,387 -- matches base exactly):
--   cplus_description 18,681 / $576,601 | lohp 5,097 / $160,239
--   xdp_course 2,952 / $91,472           | xdp_professional_cert 2,762 / $86,315
--   xdp_paid_media 1,837 / $62,161       | xdp_s12n 1,728 / $53,970
--   Direct/No Attribution 1,512 / $47,194 | search_result_page 1,063 / $32,767
--   promo_template 554 / $17,864          | entity_query_page 517 / $16,514
--   lihp 227 / $6,617 | career_academy 138 / $4,342 | browse 109 / $3,492
--   C+ Page 77 / $2,387 | role_description_page 73 / $2,192 | xdp_project 60 / $1,779
--
-- Q2 C+ Monthly (total 27,079 -- matches base exactly):
--   cplus_description 15,141 / $411,212 | lohp 3,743 / $101,729
--   xdp_professional_cert 2,567 / $66,976 | xdp_course 1,973 / $52,346
--   xdp_paid_media 1,194 / $38,392        | xdp_s12n 1,119 / $29,612
--   Direct/No Attribution 1,061 / $28,536 | lihp 106 / $2,700
--   C+ Page 69 / $1,957 | browse 64 / $1,820 | xdp_project 42 / $1,119
--
-- March Tentpole 2026 (total 38,353 -- matches base exactly):
--   cplus_description 19,182 / $3,701,920 | lohp 5,756 / $1,157,784
--   xdp_course 3,755 / $724,168            | xdp_professional_cert 3,280 / $619,591
--   xdp_s12n 2,379 / $461,380               | xdp_paid_media 1,758 / $395,038
--   Direct/No Attribution 1,443 / $298,295 | lihp 389 / $74,833
--   browse 158 / $32,687 | xdp_project 107 / $20,795 | C+ Page 87 / $16,445
--   search_result_page 26 / $4,589 | promo_template 24 / $5,437
--   entity_query_page 5 / $886 | career_academy 2 / $393 | role_description_page 2 / $377
--
-- June Tentpole 2026 (FINAL, re-pulled 2026-07-16 with the corrected 7/14 end
-- date -- total 52,201, matches base metrics exactly; up from the 2026-07-15
-- pull's total of 51,519, which was still missing 7/14's data):
--   cplus_description 29,054 / $4,549,527 | lohp 5,869 / $1,016,317
--   xdp_course 4,694 / $747,312             | xdp_professional_cert 4,459 / $674,023
--   xdp_s12n 3,577 / $563,864                | Direct/No Attribution 2,148 / $371,021
--   xdp_paid_media 1,535 / $311,950          | lihp 503 / $79,387
--   browse 147 / $25,079 | xdp_project 130 / $19,861 | C+ Page 85 / $15,272
--
-- Pattern across all 4 campaigns: "cplus_description" (the C+ plan-detail
-- page) dominates page-level attribution by a wide margin, followed by lohp
-- (logged-out homepage) and the XDP family. Consistent shape across Q1/Q2
-- C+ Monthly and both tentpoles.
-- ============================================================================
