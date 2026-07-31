---
question_id: consumer-q039
question_text: >
  Is the 40%-off-3-months M3->M4 retention cliff for C+ monthly caused by the discount expiring,
  or is it structural for all C+ monthly subs -- should we lengthen the promo window?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Diff-in-diff: compare the M3->M4 drop for the 40%-promo cohort vs full-price C+ monthly in the
same window (promo rows don't exist at payment_order=4 -- a price shock). Causal +
recommendation -> complex: confirm the comparison window and the full-price control definition
before running.

Golden answer and agent runs come in later PRs. This file only pins the question.
