# Golden answer — q008 (proposed, not yet frozen)

**Question:** What are M1, M2 and M2+ retention for C Plus monthly, and where's the biggest
drop-off?

**Correct answer (method-level):**

- Report **M1**, **M2**, and **M2+** step renewal rates for C Plus monthly from
  `prod.bi.base_data_for_ret_cancel`, using `next_txn_stamp_sub_level` as the renewal
  signal and the 7-day eligibility lag.
- **The biggest drop-off is at M1** (the first renewal) — the largest single leak.
- Retention **rises with tenure** after that (M2 > M1, and M2+ is highest).

As observed on 2026-07-24 (illustrative, not frozen): M1 ≈ 64%, M2 ≈ 70%, M2+ ≈ 81%.
The Jan-2025 cohort reproduces the documented benchmark exactly (M1 62.6 → M5 79.5).

Numbers move with the data; what is frozen is the method in `method.yaml`.
