---
question_id: consumer-q045
question_text: >
  Did completing the Google AI specialization cause subscribers to cancel (healthy 'job done'
  churn), or does it reflect a broader Professional Certificate quality problem -- should the
  subscription model change?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Compare the completion-driven-cancel share for Google AI subs vs the rest of ProfCert monthly
(a high completion-driven share = healthy job-done churn, not a quality issue). Causal +
model-change recommendation -> complex: confirm the Google AI carve-out definition and the
comparison set. Uses ret_cancel cancel_type + s12n completion.

Golden answer and agent runs come in later PRs. This file only pins the question.
