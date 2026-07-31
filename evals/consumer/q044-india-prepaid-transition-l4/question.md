---
question_id: consumer-q044
question_text: >
  Did the India prepaid-to-subscription transition (May 2026) cause the India retention/LTV
  shift, or was India already trending that way -- what does that imply for the next India
  pricing decision?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Pre/post trend-break for India retention and LTV around May 2026, using other APAC/non-NAMER
regions as control. Causal + recommendation -> complex. LTV portion needs a B2C filter first
(join user_stats_vw, user_segment='B2C' -- the LTV table mixes in enterprise/degree). Confirm
event date + control set.

Golden answer and agent runs come in later PRs. This file only pins the question.
