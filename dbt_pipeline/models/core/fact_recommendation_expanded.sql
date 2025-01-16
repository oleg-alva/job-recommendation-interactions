WITH recommendations AS (
    SELECT 
        rec.id as recommendation_id,
        rec.created_at as recommendation_expanded_at,
        rec.user_id,
        rec.job_position_id,
        rec.status as recommendation_status,
        cand.* -- Include relevant candidate fields here
    FROM {{ ref('staging__recommendation_expanded_event') }} rec
    LEFT JOIN {{ ref('staging__candidate_data') }} cand
        ON rec.user_id = cand.user_id
)

SELECT 
    recommendation_id, -- string
    recommendation_expanded_at, -- timestamp
    user_id, -- string
    job_position_id, -- string
    recommendation_status, -- string
    has_experiences, -- boolean
    -- Add additional candidate fields as needed
FROM recommendations
