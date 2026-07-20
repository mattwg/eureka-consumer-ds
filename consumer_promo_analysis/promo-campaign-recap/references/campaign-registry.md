# Campaign Registry

The current list of known promo campaigns this skill can compute cuts for. **Add new campaigns
here** as they launch — this is the one file that should need editing every quarter; nothing else
in this skill should need to change when a new campaign shows up.

> **Before adding a campaign:** discover its `promotion_id`(s) by profiling `completed_carts`
> (see [query-patterns.md](query-patterns.md) → "Discovering a new campaign's promotion_ids"), then
> **confirm the definition with the requester before finalizing** — do not infer scope from
> naming/ID clustering alone. A promo that looks like it belongs to a campaign (similar name, same
> time window) may actually be a different promo type the requester doesn't want included. See
> [known-corrections.md](known-corrections.md) → "Always confirm scope nuances" for why this
> matters.

## Q1 C+ Monthly
- `promotion_id`: 277433, 278227, 278379
- Window: 2026-02-13 to 2026-05-20
- Names: "Q1 2026 - Seize the Weekend...", "High income - Seize the Savings...", "Global Catch All - Seize the Savings..."
- Confirmed as one campaign via `promotion_id` creation-time clustering (all created within a 2-week window in Feb 2026, same pattern as the tentpoles' simultaneous regional variants).

## Q2 C+ Monthly
- `promotion_id`: 285085
- Window: 2026-04-28 to 2026-07-12
- Name: `global_2026_q2_cplusm__courseraplus_xpp_40_p____google`
- **Excluded**: `promotion_id` 286277 (`US_2026_q2_cplusm__courseraplus`) — confirmed with requester 2026-07-14 this is a different promo type, not part of this campaign.

## March Tentpole 2026
- `promotion_id`: 279246, 278665, 281016, 279263, 283280 (Euro, Global Catch All, Global High Income, LATAM, [US only] Global Catch All)
- Window: 2026-03-24 to 2026-04-29
- Product: C Plus annual
- Amplitude-side campaign name differs from the transaction-side label: **"2026 March Q1 Spring Tentpole"** (plus "Countdown Test" and "Promo Bar Test" variants) — don't assume the transaction `promotion_name` and the Amplitude `merchandisingModule.campaign.name` match.

## June Tentpole 2026
- `promotion_id`: 287775, 287768, 287767, 287771, 287769, 290356, 290357 (APAC, Global, India, LATAM, NAMER, + 2 "last chance" close-outs)
- Window: 2026-06-05 to 2026-07-14 (India starts 6/5, rest 6/8) -- this is a point-in-time
  snapshot only, NOT authoritative. An initial assumption of 7/13 went stale (the true last
  redemption was 7/14) before this was corrected. All 4 saved queries now derive each campaign's
  window dynamically (`MIN`/`MAX(transaction_ts)`, see `known-corrections.md`), so they
  self-correct without needing this field updated -- treat this line as informational only.
- Product: C Plus annual

## Confirmed excluded / not campaigns (do not add without a reason to revisit)
- `promotion_id` 278016 "40% off 3 months of C+ (Multi month) CRM" — evergreen CRM channel, not tied to a specific wave (ID doesn't cluster with either Q1 or Q2 C+ Monthly's creation window).
- `promotion_id` 249547 "March Affiliate Promo: 40% off Coursera Plus Annual" — despite the name, runs continuously since April 2025; confirmed evergreen affiliate channel, not March-specific.

## Held out / unresolved (needs a decision before including)
- `promotion_id` 277443 "SEO discount page - 40% off 3 months of C+" — evergreen-looking (runs Feb–Jul), created in the same window as Q1's promos. Unresolved: campaign or always-on placement?
- `promotion_id` 277513 "XDP banner - 40% off 3 months of C+ - low converting, low retention, standalone courses" — same open question as above.

## Q3 [add when it launches]
- `promotion_id`:
- Window:
- Notes:
