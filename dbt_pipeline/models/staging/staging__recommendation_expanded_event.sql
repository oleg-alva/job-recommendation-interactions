with
    source_expanded_recommendations as (
        select * from {{ source('alva_app_production', 'job_recommendation_expanded') }}
    ),

    source_user_relevance as (
        select * from {{ source('recommendations_events_production', 'user_relevance_information_latest_completed') }}
    ),

    source_recommendation_status as (
        select * from {{ source('recommendations_events_production', 'job_recommendation_status_changed') }}
    ),

    split as (
        select
            received_at,
            date_trunc(received_at, DAY) as day_received,
            job_recommendation_id,
            cast(split(job_recommendation_id, '_')[0] as int64) as user_id,
            cast(split(job_recommendation_id, '_')[1] as int64) as job_position_id
        from source_expanded_recommendations
    ),

    user_has_experiences as (
        select distinct ur.user_id
        from source_user_relevance ur,
            unnest(user_experiences) ue
        where true
            and array_length(user_experiences) > 0
    )

select
    received_at, -- timestamp
    day_received, -- date
    user_id, -- string
    job_position_id, -- string
    s.job_recommendation_id, -- string
    jrsc.status, -- string
    case
        when user_id in (select user_id from user_has_experiences) then true
        else false
    end as has_experiences, -- boolean
from split s
left join source_recommendation_status jrsc 
    on s.job_recommendation_id = jrsc.job_recommendation_id
order by received_at asc
