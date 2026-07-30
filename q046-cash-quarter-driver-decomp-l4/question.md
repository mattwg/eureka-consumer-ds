---
question_id: consumer-q046
question_text: >
  Is the change in total B2C cash this quarter driven by more payers, a mix shift toward higher-
  value product sub-types, or higher per-payer cash -- and where should we focus?
source: real
target_skill:
  - skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
  - skills/data-science/bhkumar/vmr-decomposition
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Absolute-numerator VMR decomposition: base = payer count, segment = product_sub_type, rate =
cash per payer. Multi-step decomposition + 'where to focus' recommendation -> complex: confirm
the two periods and the segmentation dimension before running. Routes the decomposition to the
VMR workflow.

Golden answer and agent runs come in later PRs. This file only pins the question.
