-- Query 1: High Income Pricing Test population (Test/Control + impression window)
-- Identifies the user base exposed to the High Income Pricing Test, their
-- test/control categorization, and impression start/end timestamps.
-- See SKILL.md Section 3, Query 1 for full context and the end_ts stickiness caveat.

WITH variants AS (
      SELECT
        -- Experiment metadata.
        epic_experiment_id
        , epic_experiment_started_at
        , epic_experiment_ended_ts
        , MAX(COALESCE(epic_experiment_ended_ts, CURRENT_DATE)) OVER () AS end_ts
        , epic_experiment_display_name
        -- Variant metadata.
        , epic_variant_id
        , epic_variant_weight
        , TRIM(epic_variant_name) AS cleaned_epic_variant_name
        ,
        (MAX(CASE WHEN epic_variant_index = 0 AND epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w' THEN 1 ELSE 0 END)
        OVER (PARTITION BY TRIM(epic_variant_name)))::BOOLEAN
         AS is_control
        -- Get the order of variants. Order same as EPIC unless control is manually set, in which case control is put first.
        , CASE
        WHEN is_control THEN 1
        ELSE -MIN(epic_variant_index) OVER (PARTITION BY TRIM(epic_variant_name))
        END AS sort_by
      FROM prod.bi.epic_variants
      JOIN prod.bi.epic_experiments USING (epic_experiment_id)
      WHERE (
      epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w'

      )
      AND epic_experiment_allocation_type = 'BY_USER'
      )

      SELECT
         is_control
        , user_id
        -- Get impression start and end timestamps for metrics calculations. This includes users
        , MIN(impression_ts) AS start_ts,
          MAX(end_ts) AS end_ts
      FROM prod.bi.epic_user_impressions
      JOIN variants USING (epic_experiment_id, epic_variant_id)
      WHERE
        impression_dt BETWEEN epic_experiment_started_at::DATE AND COALESCE(epic_experiment_ended_ts::DATE, CURRENT_DATE) -- speeds up the computation
        AND impression_ts BETWEEN epic_experiment_started_at AND COALESCE(epic_experiment_ended_ts, CURRENT_DATE)
        AND 1=1 -- no filter on 'impressions.impression_date'

      GROUP BY 1, 2
