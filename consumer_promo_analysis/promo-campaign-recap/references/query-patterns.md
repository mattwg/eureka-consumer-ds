# Query Patterns

Reusable patterns for each cut this skill produces. Every pattern builds on the same
`campaign_map` CTE (sourced from [campaign-registry.md](campaign-registry.md)) and the standing
corrections in [known-corrections.md](known-corrections.md) (currently six — see that file for the
full, current list). Worked, saved examples for
the current quarter live in [../queries/](../queries/) — start from those rather than rewriting
from scratch.

## Discovering a new campaign's promotion_ids

Before adding a campaign to the registry, find its `promotion_id`(s) and date window empirically —
don't guess:

```sql
SELECT
    cc.promotion_name,
    b1.product_sub_type,
    MIN(ab.transaction_ts) AS first_seen,
    MAX(ab.transaction_ts) AS last_seen,
    COUNT(*) AS redemption_count
FROM prod.gold_base.transactions ab
INNER JOIN prod.gold_base.completed_carts cc
    ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id
LEFT JOIN prod.bi.products_detail b1
    ON ab.product_item_id = b1.product_item_id AND ab.product_type = b1.product_type
WHERE ab.transaction_type = 'BUY'
  AND NOT ab.was_buy_transaction_refunded
  AND ab.transaction_business_line = 'B2C'
  AND cc.promotion_id IS NOT NULL
  AND b1.product_sub_type IN ('C Plus monthly', 'C Plus annual')
  AND ab.transaction_ts >= '<start of quarter>'
GROUP BY cc.promotion_name, b1.product_sub_type
ORDER BY first_seen
```

Cluster results by **`promotion_id` creation time** (close IDs created within days of each other =
likely one campaign's regional/segment variants, same pattern as the tentpoles) and by name
similarity — but always **confirm the grouping with the requester** before finalizing (see
known-corrections.md's "always confirm scope nuances"). Check for a 1:1 `promotion_name`↔
`promotion_id` mapping before keying on name alone:

```sql
SELECT cc.promotion_name, cc.promotion_id, COUNT(*) AS redemption_count,
       MIN(ab.transaction_ts) AS first_seen, MAX(ab.transaction_ts) AS last_seen
FROM prod.gold_base.transactions ab
INNER JOIN prod.gold_base.completed_carts cc
    ON ab.user_id = cc.user_id AND ab.cart_id = cc.cart_id
WHERE cc.promotion_name ILIKE '%<candidate name fragment>%'
GROUP BY cc.promotion_name, cc.promotion_id
ORDER BY cc.promotion_name
```

## Pattern: Base metrics (cash, redemptions, NPL/Non-NPL)

Totality + by-campaign cash and redemptions, split by payer type. Worked example:
[../queries/q2_tentpole_base_metrics.sql](../queries/q2_tentpole_base_metrics.sql).

Shape: `campaign_map` CTE → `tagged` CTE (join transactions/completed_carts/subscription_payments/
products_detail/user_stats_vw, apply the standing corrections, `COALESCE` the ID-based campaign
lookup with the SKU-fallback date-window CASE for C+ Annual) → final `SELECT` with
`GROUPING SETS ((campaign, payer_type), (campaign))` for totality + breakdown in one query.

## Pattern: Regional split

Adds `country_group_finance` (via `users_vw` → `static_countries_vw`) to the base pattern. Worked
example: [../queries/q2_region_split_2_2.sql](../queries/q2_region_split_2_2.sql). Drop the
NPL/Non-NPL dimension unless specifically asked for it alongside region — adding every dimension
to every cut makes results harder to read without adding insight.

## Pattern: Traffic source / channel

Adds `user_stats_vw.first_payment_referrer_cons_l0_mktg_chnl_ft28d` (see known-corrections.md for
the Non-NPL attribution caveat) to the base pattern. Worked example:
[../queries/q2_traffic_source_2_4.sql](../queries/q2_traffic_source_2_4.sql). For finer-than-
Organic/Paid granularity, swap in the L1–L4 variant of the same field (not yet built/tested here).

## Pattern: Page-level split (Amplitude first-touch attribution)

Redemptions/cash by page type (XDP, C+ page, LOHP/LIHP, etc.), via a 7-day first-touch look-back
before redemption. Worked example (all 4 current campaigns):
[../queries/q2_page_level_split_2_3.sql](../queries/q2_page_level_split_2_3.sql).

Shape: `redeemers` CTE (same tagging logic as the base pattern, but only `transaction_id`/
`user_id`/`transaction_ts`/cash needed) → `impressions` CTE joining redeemers to
`consolidated_amplitude_v3_events_vw` on `CAST(attributed_user_id AS BIGINT) = user_id` within a
7-day window before `transaction_ts`, matching either `ViewMerchandisingModule` or a `ViewPage` on
the C+ page → `first_touch` CTE dedup via `ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY
client_event_time ASC) = 1` → final aggregation.

**First-touch, not last-touch — confirmed intentional.** This attributes to whichever page
introduced the user to the purchase consideration within the 7-day window, not the last page before
redemption. Kept as-is on review; revisit only if a future ask specifically wants "what page
immediately preceded the redemption" instead.

**Performance**: write/run this as one query PER CAMPAIGN, each with `event_date` bounded to that
campaign's window + a 7-day lookback buffer on both ends. A combined multi-campaign version is fine
to keep as the "canonical" saved artifact, but budget for running it split if it times out (see
known-corrections.md).

**Getting the window right — two-step process, don't embed a dynamic CTE here.** Unlike the other
patterns above, do NOT compute the campaign's date window as a CTE/subquery inside this same query
— Databricks can't use a runtime-computed bound for partition pruning on `event_date`, so it scans
far more than needed (confirmed: 10+ minutes with the window embedded vs. under a minute with a
literal). Instead: (1) run a small, fast, standalone query first to resolve
`MIN`/`MAX(transaction_ts)` for the campaign's `promotion_id`s (touches only
`transactions`/`completed_carts`, seconds), then (2) paste those concrete dates as literals into
this query's `event_date` bound. This keeps the window self-correcting (freshly resolved from data
every time) without hardcoding a stale assumption, while staying fast. See
`q2_page_level_split_2_3.sql`'s header for the exact two-step queries.

## Pattern: Conversion funnel (traffic → click → checkout → purchase)

**Partially finalized — C+ Annual tentpoles, C+ landing page variant only.** Worked example:
[../queries/tentpole_conversion_funnel_2_5.sql](../queries/tentpole_conversion_funnel_2_5.sql).

Shape: 3 steps, not 4 — `ViewPage` on the C+ page (traffic) → `ClickButton` "start_cplus_annually"
(checkout-start intent) → actual redemptions (pulled from the base-metrics pattern's confirmed
totals, not re-derived here). The originally-proposed middle step (`ClickPayNowButton`, "real
checkout attempt") was dropped — it fires across all Coursera checkouts, not just C+, and returned
more users than the click step above it (an impossible funnel shape) when tried unscoped; no
reliable product-context filter was found to narrow it, so it was cut rather than shipped broken.

**Still open, do not silently reintroduce:**
- **The promotion-landing-page variant is not included.** The original ask wanted "C+ landing page
  vs. promotion landing page" broken out separately; only the C+ landing page half is built. A
  `promo_template` `page.type` hypothesis for "promotion landing page" was tried and never
  confirmed against a real URL (verification queries timed out twice) — don't add it back without
  confirming the actual page/URL first.
- **Not yet extended to C+ Monthly** — only March/June Tentpole 2026 are covered.
- **Step 1 (C+ page traffic) mixes Monthly- and Annual-intent visitors** — the C+ page shows both
  plans, and there's no reliable way to split intent from a landing-page visit alone. This matches
  the original reference query's own step-1 definition (same limitation, not a new gap). Step 2
  (`start_cplus_annually`) is Annual-specific, so the step-2→3 rate is a clean Annual-only
  conversion rate; the step-1→2 rate is diluted by the mixed-intent step-1 denominator.

## Pattern: C+ landing page performance (conversion rate, not just redemption count)

Not started. Needs a **denominator** (visitors to the page, not just redeemers) — closer to the
funnel pattern's `step1_traffic` than to the page-level-split pattern above. Needs a definitional
decision on what counts as "the standard promo page" to compare against (see the parked discussion
in the source conversation).
