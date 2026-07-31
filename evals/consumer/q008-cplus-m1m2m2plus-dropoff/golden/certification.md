# q008 certification record

This is the external evidence that certifies the frozen golden. Per `evals/README.md`, a
golden is only trustworthy if a codeowner checked it against a source **outside** the agent's
own run. That check is recorded here so it survives beyond the PR thread.

- **Question:** M1, M2, M2+ retention for C Plus monthly; where's the biggest drop-off?
- **Certified by:** @bhkumar-coursera
- **When / where:** PR #112 review, 2026-07-24
- **Anchor type:** Looker dashboard (independent of the agent)

## External anchor

Looker — `EDS_Consumer_KPI` / `new_retention_metrics`:

<https://looker.dkandu.me/explore/EDS_Consumer_KPI/new_retention_metrics?qid=n5uPq6W9nShuCcCwrxyHFa&origin_space=4362>

The reviewer ran this explore and confirmed the agent's numbers **matched** it. (A `qid`
link can expire; the explore is `EDS_Consumer_KPI / new_retention_metrics` if the link rots.)

A secondary anchor: the Jan-2025 C+ monthly benchmark in the skill's `metric-definitions.md`
(M1 62.6 / M2 67.8 / M3 74.8 / M4 78.5 / M5 79.5), reproduced to the decimal by the
certifying run in `../runs/2026-07-24/`.

## Interpretation calls the reviewer confirmed

1. **Cohort:** no cohort was specified, so the run blended all matured cohorts. Reviewer
   confirmed this is the intended reading (payment retry attempts happen up to 7 days, so
   only matured cohorts are counted).
2. **M2+ definition:** `payment_order >= 2`, aggregated. Confirmed.

## Reviewer's verbatim comment (PR #112)

> 1. Certify against an outside source (a Looker retention dashboard / prior report), not
> against this run. Fill in certified_against in golden/method.yaml.
> https://looker.dkandu.me/explore/EDS_Consumer_KPI/new_retention_metrics?qid=n5uPq6W9nShuCcCwrxyHFa&origin_space=4362 this is the looker and it matched.
>
> 2. Confirm two interpretation calls I flagged: No cohort was specified → I blended all
> matured cohorts. Is that what the pod means, or a named recent cohort? I did not get this
> part, but yes we should take the blended matured cohort as payment retry attempts happen
> till 7 days.
>
> 3. read "M2+" as payment_order ≥ 2 aggregate. Confirm. : Yes thats correct.
