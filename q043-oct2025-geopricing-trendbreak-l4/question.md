---
question_id: consumer-q043
question_text: >
  Did the October 2025 geo-pricing change cause the non-NAMER retention drop, or was it already
  declining beforehand -- and what should pricing do next?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Diff-in-diff: non-NAMER retention pre/post Oct 2025 against NAMER (unaffected control),
checking for confounding promo/mix shifts. Causal + pricing recommendation -> complex: confirm
the event date, the control region, and the metric (M1? blended?). Depends on the pricing-
calendar event being real.

Golden answer and agent runs come in later PRs. This file only pins the question.
