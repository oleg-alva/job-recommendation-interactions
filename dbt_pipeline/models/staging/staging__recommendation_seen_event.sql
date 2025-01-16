with
    source_viewed_recommendations as (
        select * from {{ source('alva_app_production', 'viewed_job_recommendations') }}
    ),

    source_user_relevance as (
        select * from {{ source('recommendations_events_production', 'user_relevance_information_latest_completed') }}
    ),

    source_recommendation_status as (
        select * from {{ source('recommendations_events_production', 'job_recommendation_status_changed') }}
    ),

    unnested as (
        select
            vjr.received_at,
            date_trunc(vjr.received_at, DAY) as day_received,
            replace(
                replace(
                    replace(unnested_job_recommendation_id, '"', ''),
                    '[',
                    ''
                ),
                ']',
                ''
            ) as recommendation_id
        from source_viewed_recommendations as vjr,
            unnest(split(vjr.job_recommendation_ids, ',')) as unnested_job_recommendation_id
    ),

    user_has_experiences as (
        select distinct ur.user_id
        from source_user_relevance ur,
            unnest(user_experiences) ue
        where true
            and array_length(user_experiences) > 0
    ),

    split as (
        select
            received_at,
            day_received,
            recommendation_id,
            cast(split(recommendation_id, '_')[0] as int64) as user_id,
            cast(split(recommendation_id, '_')[1] as int64) as job_position_id
        from unnested
    ),

    ranked_recommendations as (
        select
            received_at,
            day_received,
            user_id,
            job_position_id,
            recommendation_id,
            ROW_NUMBER() over (partition by recommendation_id order by day_received) as time_shown,
            row_number() over (
                partition by user_id, received_at
                order by received_at asc
            ) as row_num
        from split
    )

select
    received_at, -- timestamp
    day_received, -- date
    user_id, -- string
    job_position_id, -- string
    recommendation_id, -- string
    jrsc.status, -- string
    time_shown, -- int
    case
        when user_id in (select user_id from user_has_experiences) then true
        else false
    end as has_experiences, -- boolean
    row_num, -- int
    case
        when row_num = 1 then true
        else false
    end as is_first_recommendation -- boolean
from ranked_recommendations
left join source_recommendation_status jrsc 
    on recommendation_id = jrsc.job_recommendation_id
order by received_at asc
