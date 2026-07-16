-- Query 8: Country-level split of registrations, Test vs Control.
-- Same structure as Query 5 (channel split check), but cuts by user_country_cd
-- instead of L0 channel. Part of the "country level breakdown at the traffic
-- split" nuance from SKILL.md Section 2.

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
        , TRIM(REGEXP_REPLACE(epic_variant_name, '', '')) AS cleaned_epic_variant_name
        ,
        (MAX(CASE WHEN epic_variant_index = 0 AND epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w' THEN 1 ELSE 0 END)
        OVER (PARTITION BY TRIM(REGEXP_REPLACE(epic_variant_name, '', ''))))::BOOLEAN
         AS is_control
        -- Get the order of variants. Order same as EPIC unless control is manually set, in which case control is put first.
        , CASE
        WHEN is_control THEN 1
        ELSE -MIN(epic_variant_index) OVER (PARTITION BY TRIM(REGEXP_REPLACE(epic_variant_name, '', '')))
        END AS sort_by
      FROM prod.bi.epic_variants
      JOIN prod.bi.epic_experiments USING (epic_experiment_id)
      WHERE (
      epic_experiment_id = 'kEs8FDkHEfGErBK2XQAA3w'

      )
      AND epic_experiment_allocation_type = 'BY_USER'
      ),
cohort_users_details AS (
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

      GROUP BY 1, 2),
channel_impression_user_level_data AS (
SELECT a.*,
       b.user_country_cd
FROM cohort_users_details a
LEFT JOIN (SELECT DISTINCT user_id,user_country_cd
           FROM prod.gold.user_stats_vw
           WHERE user_id IN (SELECT DISTINCT user_id FROM cohort_users_details))b
ON a.user_id=b.user_id)
SELECT user_country_cd AS country,
       is_control,
       COUNT(DISTINCT user_id) AS user_count
FROM channel_impression_user_level_data GROUP BY 1,2
ORDER BY 1, 2, 3 DESC
