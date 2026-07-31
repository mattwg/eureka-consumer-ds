# Pull-Forward / Cannibalization Testing Framework

A reusable method for questions shaped like "did Promo A steal demand from Promo B" (e.g. "did
stacking a C+ Monthly promo before a tentpole pull forward the tentpole's cash"). Built from
working through the "May C+ Monthly → June Tentpole" hypothesis in this quarter's post-mortem.

> **Scope note:** this is RCA-type methodology (diagnosing *why*, not computing *what*). It
> overlaps with `promo-metric-rca`'s stated purpose ("did C+ Monthly cannibalize C+ Annual
> tent-pole demand?" is literally one of its listed use cases) and that skill's
> `decomposition-playbook.md`. Kept here for now rather than proposed into that skill — revisit
> if/when it makes sense to contribute this there instead.

## Step 0 — Define the claim precisely before touching data

"Did A pull forward B's demand" specifically means: a purchase that would have happened during
B's window happened during A's window instead, because A intercepted the buyer earlier. This is
**not the same as**:
- **Cross-buy / upsell** — a person buying both A and B. That's two separate purchases, i.e.
  incremental revenue, not a stolen sale.
- **Raw overlap** — necessary to check, but on its own proves nothing about pull-forward (see
  Step 1).

## Step 1 — Direct buyer-overlap check (cheap, do first, but it does NOT answer the question)

Count how many of A's buyers also bought B. This sizes the cross-buy/upsell funnel, which is
useful context — but **true pull-forward victims are invisible in this check**, because someone
who bought A *instead of* B simply never shows up in B's buyer list at all. A low overlap number
does not mean pull-forward didn't happen; it means direct cross-buy is small. Don't over-read this
number as answering the core question — it answers a different, adjacent one.

```sql
-- Pattern: overlap between A's buyer list and B's buyer list
WITH a_buyers AS (SELECT DISTINCT user_id FROM ... WHERE <A's promo/date filter>),
     b_buyers AS (SELECT DISTINCT user_id, transaction_id, cash_receipt_usd_estimate
                  FROM ... WHERE <B's promo/date filter>)
SELECT COUNT(DISTINCT a.user_id) AS a_buyers,
       COUNT(DISTINCT b.user_id) AS also_bought_b,
       ROUND(100.0 * COUNT(DISTINCT b.user_id) / NULLIF(COUNT(DISTINCT a.user_id), 0), 2) AS overlap_pct,
       SUM(b.cash_receipt_usd_estimate) AS b_cash_from_overlap
FROM a_buyers a LEFT JOIN b_buyers b ON a.user_id = b.user_id
```

## Step 2 — Check whether A has a genuine steady-state, or whether it's shaped like a designed lead-in

Pull A's own weekly/daily volume across its full lifetime (not just near B). If A is flat most of
the time and only spikes in the weeks right before B launches, that shape is *consistent with*
(not proof of) A being **designed** to feed into B — **the shape alone cannot tell you whether the
timing is deliberate or coincidental; you must confirm with whoever owns the promo calendar.**
This isn't a formality: in this skill's worked example, the shape looked exactly like designed
sequencing, but the calendar owner confirmed it was actually coincidental. Getting this wrong
matters — "designed" implies the audience overlap was a deliberate, accepted trade-off, while
"coincidental" means no one has managed that risk at all. This step also determines whether Step
3's "excess volume above baseline" approach is even viable — if there's no steady baseline, there's
nothing to measure an "excess" against, regardless of which way the designed/coincidental question
resolves.

## Step 3 — Look for a genuinely unstacked comparison instance (if one exists)

Find a prior instance of B (or a similar campaign) that did NOT have A stacked before it. Compare
per-week-normalized volume between the stacked and unstacked instances.

**Critical caveat — check for confounds before trusting the comparison:**
- **Seasonality/calendar position** — e.g. a January tentpole benefits from New Year's-resolution
  demand independent of any promo strategy; this alone can dwarf any stacking effect.
- **Campaign structure differences** — number of geo/segment variants, discount depth, pricing
  structure (flat-price vs. %-off) all differ instance to instance and confound magnitude
  comparisons on their own.
- Apply the same "benchmark choice drives the answer" discipline used elsewhere in the promo
  skill docs — match discount depth + geo-pricing regime + seasonal calendar position, or the
  comparison isn't clean enough to attribute a magnitude gap to stacking specifically.

If the confounds are too large to control for (as they were for New Year vs. March/June in this
analysis), be honest that this step doesn't resolve the question rather than forcing a conclusion.

## Step 4 (optional, if more rigor is needed and time allows) — Characteristic/propensity comparison

Compare the "at-risk" buyers (A's buyers from the pre-B ramp window) against A's own typical
off-peak buyer profile (region, price tier, etc.) — NOT against B's overall profile, since A and B
may already have structurally different baseline audiences unrelated to any ramp-window effect
(e.g. C+ Monthly already skews NAMER/EMEA with near-zero India, similar to Annual's mix, generally
— so comparing the ramp window to Annual's mix adds little; comparing it to Monthly's *own*
non-ramp-window mix is the informative comparison). A real shift between ramp-window and off-peak
profiles is corroborating evidence; an identical profile means the ramp isn't attracting a
qualitatively different audience.

## Step 5 — Synthesize with appropriate humility

This is fundamentally a **counterfactual question** ("what would have happened without A") and is
rarely fully resolvable from observational data alone. State findings as directional evidence with
explicit caveats, not proof, unless a true experiment/holdout exists (a group deliberately not
shown Promo A, compared on their eventual B conversion rate). If leadership needs a definitive
answer, recommend that experiment rather than overclaiming from a correlational read.

## Worked example outcome (May C+ Monthly → June Tentpole, 2026-07)

- Step 1: 0.4% overlap (89 of 22,202 May buyers also bought the June tentpole) — small cross-buy
  funnel, doesn't itself answer the pull-forward question.
- Step 2: Both March and June's preceding C+ Monthly waves showed an identical ramp-then-crater
  shape. The shape alone looked like it could be a designed lead-in — **but confirmed with the
  requester it's actually coincidental**, not planned. Lesson: don't stop at "the shape suggests
  X" — this step's instruction to confirm with the calendar owner is not optional decoration, it
  changed the actual answer here. The crater at launch is most likely the tentpole simply taking
  over shared marketing placements, not a two-step funnel.
- Step 3: New Year tentpole (genuinely unstacked) ran ~1.4–1.9x March/June's per-week rate
  (narrower once June's final, fully-reconciled numbers came in vs. the provisional pull), but
  confounded by seasonality (New Year's resolutions) and campaign structure (8 variants + a flat-
  price offer vs. 5-7 uniform %-off variants) — not clean enough to attribute to stacking alone.
- Step 4: skipped as low-incremental-value given what Step 2/existing region data already showed.
- Conclusion: no strong evidence of harmful pull-forward from the direct-overlap evidence (which
  holds regardless of intent) — but since the timing turned out to be coincidental rather than
  designed, this is more of an open question for future promo-calendar planning than "confirmed
  fine by design." Directional read only, not fully causal.
