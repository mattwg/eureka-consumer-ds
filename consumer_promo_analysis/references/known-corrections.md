# Known Corrections & Lessons Learned

Standing corrections to apply to every cut, plus process lessons from building this skill. Read
this before writing a new query from scratch — every one of these was found by cross-checking a
naive first pass against a production reference query or against the requester, and each one
materially changed the numbers.

## The standing query corrections

Apply all of these to any query counting promo redemptions or cash, regardless of which cut:

1. **`payment_order = 1 OR payment_order IS NULL`** — a "redemption" is a subscription's FIRST
   payment, not every recurring charge. Without this filter, recurring products (C+ Monthly)
   have redemptions/cash inflated ~2x by renewal billing folded in as if it were new redemptions.
   One-time products (C+ Annual) are unaffected either way, but always include the filter for
   consistency and because it's harmless when there's nothing to filter.
2. **C+ Annual promo-SKU dual detection**: `product_item_id = '<current SKU>'` (currently
   `GMM31Io6RjODN9SKOuYz_A` — confirm this is still current before trusting it, SKUs get rotated)
   **OR** `promotion_id IS NOT NULL`. Some tentpole redemptions apply the discount via the SKU
   without populating `promotion_id`. Missing this undercounts tentpole redemptions materially
   (was ~17% low on March Tentpole redemptions before this fix). Only applies to C+ Annual — not
   a documented issue for C+ Monthly. **Use `product_item_id`, not `underlying_product_item_id`**
   — a reference query shared during this analysis used the wrong column and its promo flag never
   fired via the SKU path (verified empirically: the SKU value matched 5,888 rows on
   `product_item_id` and zero on `underlying_product_item_id` in one campaign's window).
   Since there's no `promotion_id` to map these redemptions to a specific campaign by name, bucket
   them by the campaign's date window instead (see [query-patterns.md](query-patterns.md)).
3. **2-day late-arrival reconciliation trim**: `DATE(transaction_ts) <= CURRENT_DATE - 2`. Don't
   quote the last 48h as final. **Caveat**: if a campaign's window runs right up to "yesterday,"
   this trim cuts into the campaign's own final days, not just extra data beyond it — numbers for
   a just-ended campaign are provisional until re-run a couple of days later.
4. **Pad any campaign end-date upper bound by +1 day when using it as a filter.** Promos are
   scheduled/run in whatever local time zone the marketing team uses (e.g. Pacific); `transaction_ts`
   is stored in UTC. Late-in-the-day local-time activity lands on the *next* UTC calendar date, so a
   strict `DATE(transaction_ts) <= end_date` filter (using a UTC-derived or externally-provided
   end_date) can silently cut off the last few real hours of a campaign. This applies whenever an
   end-date is used as an upper-bound FILTER — e.g. the SKU-fallback date range (correction #2) and
   any Amplitude lookback window — not when simply *observing/reporting* a MIN/MAX date (that
   should stay the raw observed value). Kept as a simple universal +1 day pad rather than modeling
   the actual time zone, since promos may run in different zones and exact modeling isn't worth the
   complexity for the size of the effect (a few hours per boundary).
5. **Ask the requester for the campaign's authoritative start/end date FIRST — don't default to
   deriving it from data.** Data-derived dates (`MIN`/`MAX(transaction_ts)`) can be unreliable for
   two reasons: (a) the timezone spillover in correction #4, and (b) a campaign "type" is often made
   up of several different `promotion_id`s/names that each show a different, noisy individual
   first/last-redemption date (see #6 below) — none of which may match the campaign's true official
   window. **Priority order: ask the requester for the official start/end date first; only fall
   back to deriving it from data if they don't have it.** This reverses the earlier approach in
   this skill (fully dynamic derivation, no questions asked) — that approach fixed one real bug
   (a stale hardcoded date) but isn't a substitute for the requester's own authoritative source
   when they have one.
6. **One common start/end date applies to an entire campaign TYPE, not to each individual
   `promotion_id`/name within it.** E.g. "Q1 C+ Monthly" is made up of 5 different promotion_ids
   (Seize the Weekend, 2 Seize the Savings variants, SEO discount page, XDP banner) that each show
   a different first/last-redemption date in the data — that's noise, not a real distinction.
   Get ONE shared, requester-confirmed date range for the whole type, and apply it as a date filter
   **on top of** (in addition to) the `promotion_id` membership filter. This has a useful side
   effect: it naturally trims any promo that runs longer than the campaign's official window (e.g.
   an evergreen-looking placement also reused across other campaigns) down to just the slice that
   falls inside the confirmed window — resolving "is this promo in or out" without a separate
   judgment call for it.

FinAid exclusion (the 5 FinAid `promotion_id`s) is usually *not* needed on top of these three if
you're joining to an explicit campaign_map of known-good promotion_ids (none of which are FinAid)
— it's only needed for broader, unscoped promo queries.

## Amplitude-specific findings

- **The real channel/attribution field already exists — don't parse UTMs from scratch.**
  `prod.gold.user_stats_vw.first_payment_referrer_cons_l0_mktg_chnl_ft28d` is a pre-built
  "Conservative Level 0 marketing channel" field (28-day first-touch lookback), with L1–L4
  variants for finer granularity than the L0 binary (Organic/Paid). **Caveat**: it's keyed to the
  user's first payment EVER — clean attribution for NPL redemptions, but for Non-NPL
  (renewal/reactivation) redemptions it reflects the user's original signup channel, possibly
  years earlier, not what drove this specific redemption.
- **Page-type / merchandising attribution**: use a 7-day first-touch look-back before redemption —
  either a `ViewMerchandisingModule` event (`event_properties.'page.type'`) or, as fallback, a
  `ViewPage` on the C+ page (`event_properties.'page.url' ILIKE '...courseraplus%'`). Take
  whichever happened first in that window. **Do not hardcode expected
  `merchandisingModule.campaign.name` values** — the real names differ from the transaction-side
  `promotion_name` (e.g. March Tentpole's Amplitude name is "2026 March Q1 Spring Tentpole," not
  "March Tentpole 2026"), and a hardcoded name list will silently miss data as campaigns get
  renamed or new variants launch. Confirmed this tracking exists for BOTH C+ Monthly and C+ Annual
  tentpole redemptions — don't assume it's Monthly-only just because a reference table/query only
  covered Monthly.
- **`static_countries_vw` has undocumented columns.** Its YAML doc in
  `table-discovery/promotions-tables` only lists `country_cd`/`country_name` (flagged "partial
  schema") — the live table also has `country_group_finance`, `country_group_ds`, and
  `country_group_pr`, three DIFFERENT regional bucketing conventions. Use
  `country_group_finance` for region cuts — it matches the NAMER/EMEA/India/Non-India
  APAC/LatAm buckets referenced elsewhere in the promo skill docs. Always check the live schema
  (`DESCRIBE TABLE`) rather than trusting a YAML flagged as partial.

## Process lessons

- **Always confirm scope nuances with the requester — don't infer from naming/ID clustering
  alone**, even when the evidence looks strong. `US_2026_q2_cplusm__courseraplus` looked like it
  belonged in Q2 C+ Monthly (same naming pattern, overlapping dates) but the requester later
  clarified it's a different promo type not of interest. This is a standing rule for this skill,
  not a one-off judgment call — surface the specific ID/name and ask.
- **Amplitude joins need tight `event_date` bounds on BOTH ends, scoped per campaign.** A single
  query joining all campaigns' redeemers to Amplitude events with only a lower-bound date filter
  did not complete even after ~10 minutes. Splitting into one query per campaign, each bounded to
  that campaign's own window + a lookback buffer (e.g. 7 days), completed in under a minute each.
  Budget for this when building any new Amplitude-based cut — write it as N per-campaign queries
  (or run them that way) rather than one combined query, even if a combined version is what ends
  up saved as the "canonical" artifact.
- **Reference/production queries can have real bugs — verify empirically, don't just adopt them.**
  Two bugs were found in queries shared during this analysis: a wrong column
  (`underlying_product_item_id` vs `product_item_id`) that silently disabled a promo-detection
  path, and an operator-precedence issue in a CASE expression (`A AND B or C` parses as
  `(A AND B) OR C`, not `A AND (B OR C)`). Cross-check any borrowed query's logic against the data
  before trusting its output, the same way you'd check your own.
- **A campaign's assumed end date (from initial discovery) can go stale — always quote the
  observed min/max transaction date alongside results.** June Tentpole 2026 was initially assumed
  to end 7/13 (from an early profiling pass); its actual last redemption was 7/14. Because the
  hardcoded end date was baked into the SKU-fallback date-range logic (see correction #2 above),
  results looked "final" on 7/15 but were still silently missing 7/14's data — the 2-day
  reconciliation trim, not the wrong end date, was the actual constraint at that point, which
  made the gap easy to miss. Rather than fully automating a dynamic end-date lookup (which has its
  own failure mode — a single stray late transaction on an old `promotion_id` could inflate a
  derived window and cause the SKU-fallback logic to misattribute unrelated later transactions),
  the fix adopted: **derive each campaign's window dynamically** (a `march_window`/`june_window`
  CTE computing `MIN`/`MAX(transaction_ts)` per campaign) instead of hardcoding it, so the window
  self-corrects on every run. This works cleanly for `transactions`/`completed_carts`-only queries
  (base metrics, region, channel) — see `q2_tentpole_base_metrics.sql` for the pattern.
- **For any query that also joins the Amplitude events table, do NOT embed the dynamic window as
  a subquery/CTE in the same query — split it into two steps instead.** Tried embedding
  `CROSS JOIN june_window` (a CTE computing the window) directly into a query that also joins
  `consolidated_amplitude_v3_events_vw` on `event_date` — it did not complete even after ~10
  minutes (same symptom as the original "Amplitude joins need tight date bounds" issue, despite
  a window CTE being present). Likely cause: Databricks can only use a **literal** value for
  partition pruning on `event_date` at plan time — a bound computed from another table at runtime
  isn't available early enough to prune partitions, so the query scans far more than it needs to.
  **Fix: resolve the window with a small, fast, standalone query first (touches only
  `transactions`/`completed_carts`, completes in seconds), then paste those concrete dates as
  literals into the Amplitude-joined query.** This keeps the "don't hardcode a stale assumption"
  benefit (the window is freshly resolved from data every time, not typed from memory) while
  avoiding the specific SQL construct that breaks partition pruning. Confirmed: the same query
  with literal dates from a fresh resolve completed in under a minute; with the dynamic CTE
  embedded, it didn't complete in 10+. See `q2_page_level_split_2_3.sql`'s header for the
  two-step process this produced.
