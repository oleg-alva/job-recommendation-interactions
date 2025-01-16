with source as (
    select *
    from {{ source('recommendations_events_production', 'user_relevance_information_updated') }}
),

staged as (
    select
        -- IDs
        user_id,
        id,
        
        -- Timestamps
        updated_at,
        
        -- Profile Information
        preferred_job_family,
        interested_in_leadership_positions,
        linkedin_profile_url,
        
        -- Array Fields
        preferred_company_types,
        preferred_specialties,
        preferred_industries,
        preferred_cities,
        preferred_work_locations,
        spoken_languages,
        
        -- Experience Records
        user_experiences,
        CASE 
            WHEN array_length(user_experiences) > 0 THEN TRUE
            ELSE FALSE
        END as has_experiences
    from source
)

select * from staged
