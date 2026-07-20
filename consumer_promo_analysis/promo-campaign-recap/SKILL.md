---
name: promo-campaign-recap
description: "Consumer (B2C) promo campaign performance recap — given a set of promo campaigns (tentpoles, C+ Monthly waves, etc.) and a date range, computes the standard set of cuts (cash, redemptions, NPL/Non-NPL, region, traffic source/channel, page-level attribution) the same way each time, and grows an extensible registry of known campaigns as new ones launch. Use when asked for a quarterly/tentpole post-mortem, 'how did campaign X do broken out by region/page/channel,' or a multi-campaign performance comparison. Mentions completed_carts, promotion_id, promotion_name, cash_receipt_usd_estimate, NPL, C+ Monthly, C+ Annual, tentpole. Do NOT use for a single ad-hoc metric pull (use promo-metrics-lookup) or for diagnosing why a metric moved (use promo-metric-rca) — this skill assembles on top of both."
compatibility:
  requires: Coursera Data MCP (MintMCP) for live Databricks query execution
metadata:
  author: atonge
  pod: consumer_and_degree_strategy_ds / consumer_ds
  version: 0.1.0
  mcp-server: databricksmc
---

# Promo Campaign Recap

Given a set of promo campaigns, computes the standard recap cuts (cash, redemptions, payer type,
region, channel, page-level attribution) the same way every time, reusing corrections and
methodology that took real work to get right the first time. Built from the Q2 2026 tentpole
post-mortem (Q1/Q2 C+ Monthly, March/June Tentpole) — that work is the worked example this skill
generalizes from.

**Design goal: easy to extend.** New campaigns get added to one small file
([references/campaign-registry.md](references/campaign-registry.md)) without touching the
methodology or corrections. New teammates picking this up should be able to add a campaign or a new
cut without re-deriving the corrections that are already documented. Note: each saved query in
[queries/](queries/) embeds its own `campaign_map` CTE by design (so a saved query stays a
self-contained, runnable artifact) — adding a campaign to the registry doesn't automatically update
already-saved queries; a new/changed campaign still needs its `campaign_map` added to whichever
saved queries should include it.

## When to Use This Skill

- "Can we get a Q3 tentpole post-mortem — cash/redemptions in total and by campaign?"
- "Break out [campaign]'s performance by region / page type / traffic channel."
- "How do C+ Monthly and C+ Annual tentpole redemptions compare this quarter?"
- Any ask matching the "Deep dive on: regional split / page-level split / traffic source /
  conversion funnel / C+ landing page" pattern from a stakeholder recap request.

## Workflow

1. **Scope the campaigns.** Check [references/campaign-registry.md](references/campaign-registry.md)
   for known campaigns. If a campaign isn't there yet, discover its `promotion_id`(s) empirically
   (see [references/query-patterns.md](references/query-patterns.md) → "Discovering a new
   campaign's promotion_ids") and **confirm the definition with the requester before adding it** —
   see the "always confirm scope nuances" lesson in
   [references/known-corrections.md](references/known-corrections.md). Don't infer scope from
   naming/ID clustering alone, even when it looks obvious. **Two questions to ask the requester at
   this stage, every time (see known-corrections.md #5-6):**
   - "Do you have the official start/end date for this campaign?" — ask first, don't default to
     deriving it from data (data-derived dates can be unreliable: timezone spillover, and
     individual `promotion_id`s within one campaign type often show different, noisy dates).
   - If the campaign is made up of multiple `promotion_id`s/names (a "type" like "Q1 C+ Monthly"),
     confirm ONE shared date range applies to all of them, and apply it as a filter on top of the
     `promotion_id` membership filter — not each ID's own individually-observed window.
2. **Scope first, then work one cut/hypothesis at a time.** Agree on objectives + which cuts are
   needed before running anything; don't front-load every cut/query at once.
3. **Apply the standing corrections** — see
   [references/known-corrections.md](references/known-corrections.md) for the current full list of
   what each one fixes and why. These are not optional per-cut — they apply regardless of which cut
   you're building.
4. **Pick the cut(s) needed** and start from the matching worked pattern in
   [references/query-patterns.md](references/query-patterns.md) (base metrics, region, channel,
   page-level, or the not-yet-finalized funnel/C+-landing-page patterns) — reuse a saved query in
   [queries/](queries/) rather than rewriting from scratch.
5. **Cross-check against any existing reference/production query** the requester can share before
   trusting your own first draft — this caught two real bugs (the wrong SKU-detection column, and
   the payment_order/renewal-inflation issue) during this skill's development. Don't skip this step
   just because your own query looks reasonable.
6. **Run it** via the Databricks MCP read-only tool (`databricksmc__execute_sql_read_only`; poll
   with `databricksmc__poll_sql_result`). For any Amplitude-based cut, budget for running it one
   campaign at a time with tight `event_date` bounds — a combined multi-campaign query can take
   several minutes or fail to complete (see known-corrections.md's performance lesson).
7. **Save the finished query** to [queries/](queries/) with a header comment documenting: what
   corrections were applied and why, any judgment calls made, a consistency-check note (does the
   new cut's total match the base metrics total?), and known caveats (e.g. a campaign still inside
   the reconciliation window is provisional).
8. **Quote the observed `MIN`/`MAX(transaction_ts)`** for the campaign's `promotion_id`s alongside
   any result or finding (a one-line note is enough) — campaign end dates get hardcoded in a few
   places (the SKU-fallback date range, the campaign registry) and can go stale if the real last
   redemption lands later than initially assumed. Surfacing the observed range lets whoever reads
   the finding catch a stale assumption instead of it going unnoticed (see known-corrections.md).

## Quick Start

**Base metrics for a known campaign, from the registry:**
```sql
-- Full worked example: queries/q2_tentpole_base_metrics.sql
WITH campaign_map AS (
    SELECT * FROM VALUES
        (285085, 'Q2 C+ Monthly')  -- promotion_ids from campaign-registry.md
    AS t(promotion_id, campaign)
)
-- ... join chain + standing corrections + GROUPING SETS for totality + breakdown
-- see queries/q2_tentpole_base_metrics.sql for the full pattern
```

## Reference Files

| File | Use When |
|------|----------|
| [references/campaign-registry.md](references/campaign-registry.md) | You need a campaign's `promotion_id`(s)/date window, or are adding a new campaign |
| [references/known-corrections.md](references/known-corrections.md) | You need the standing corrections, the real Amplitude field names, or a process lesson from past mistakes |
| [references/query-patterns.md](references/query-patterns.md) | You need the reusable shape for a specific cut (base/region/channel/page-level/funnel) |
| [references/pull-forward-cannibalization-framework.md](references/pull-forward-cannibalization-framework.md) | You're asked "did Promo A steal demand from Promo B" — a step-by-step method plus the confounds that break naive comparisons |
| [queries/](queries/) | Worked, saved, run queries for the current quarter — start here before writing something new |

## Out of Scope (refuse / redirect)

- **A single ad-hoc metric pull** not tied to a multi-cut campaign recap → use
  [promo-metrics-lookup](../../../../bizml/promotions/promo-metrics-lookup/SKILL.md) instead.
- **Diagnosing why a metric moved** (benchmark mismatches, calendar effects, etc.) → use
  [promo-metric-rca](../../../../bizml/promotions/promo-metric-rca/SKILL.md); this skill produces the
  numbers RCA diagnoses, it doesn't diagnose them itself. **Exception**: pull-forward/cannibalization
  testing (e.g. "did Promo A steal demand from Promo B") is kept here for now — see
  [references/pull-forward-cannibalization-framework.md](references/pull-forward-cannibalization-framework.md)
  — even though it overlaps with promo-metric-rca's stated scope, since that's a different pod's
  skill and this methodology was developed working through this quarter's post-mortem.
- **Actual LTV/RPU/revenue/elasticity values as a stored/authoritative source** — non-public
  financials; always recompute live for reporting or decision-making, never treat a past result as
  current truth. **Narrow exception**: a saved query's header comment may include a dated "Results
  as of [date]" snapshot (e.g. `Total 52,201 / $8,373,614`) purely as a point-in-time consistency
  check — so a future run can compare against it and catch drift/staleness (see known-corrections.md's
  staleness lesson) — not as a number to quote or reuse in place of a fresh query.
- **Adding or changing a campaign definition without requester confirmation** — always ask, even
  when the naming/timing looks obvious. See known-corrections.md.
- **Any table this skill doesn't document** — say so and stop rather than guessing a table/column.

## Related Skills

- [promo-metrics-lookup](../../../../bizml/promotions/promo-metrics-lookup/SKILL.md) — canonical
  single-metric definitions and the base join chain this skill's patterns are built on.
- [promo-metric-rca](../../../../bizml/promotions/promo-metric-rca/SKILL.md) — diagnoses *why* a
  metric moved once this skill has produced the numbers.
- [table-discovery/promotions-tables](../../../../../table-discovery/promotions-tables/SKILL.md) —
  table schemas; check the LIVE schema (`DESCRIBE TABLE`) before trusting a YAML flagged "partial."
- [`CLAUDE.md`](CLAUDE.md) — general analysis behavior guidelines (state assumptions, avoid
  overcomplication, precision) scoped to this skill only.
