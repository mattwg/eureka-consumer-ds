---
question_id: consumer-q040
question_text: >
  Are completion-driven ('good') cancels for Specialization monthly (~21% of ended subs) masking
  what looks like a churn problem -- should reporting net them out?
source: real
target_skill: skills/data-science/consumer_and_degree_strategy_ds/consumer_ds/consumer-ds-metrics-lookup
ground_truth_status: draft
grading: method
level: L4
eval_class: complex
---

Split ended subs into completion_driven_cancel vs true_churn; compare true-churn-only rate to
the raw ended-sub rate. Recommendation on a reporting change -> complex: confirm scope (which
products; does NOT apply to C+ all-access) and the completion window.

Golden answer and agent runs come in later PRs. This file only pins the question.
