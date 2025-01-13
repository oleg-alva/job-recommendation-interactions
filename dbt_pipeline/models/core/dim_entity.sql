WITH ordered_changes AS (
  SELECT
    *,
    -- Get the latest version of each product's charges
    max(charge_version)
      OVER (PARTITION BY product_id)
      AS latest_charge_for_product
  FROM {{ ref('staging__product_charges') }}
  -- Missing charged_through_date indicates future charges
  WHERE charged_through_date IS NOT NULL
  -- Charges that have the Credit status have been revoked
  AND charge_change_state != "Credit"
  -- Only include recurring charges
  AND charge_type = "Recurring"
  -- Only include charges that are currently active
  AND effective_start_date
  <= date(parse_timestamp("%Y-%m-%d %H:%M:%E6S%Ez", "{{ run_started_at }}"))
  AND effective_end_date
  >= date(parse_timestamp("%Y-%m-%d %H:%M:%E6S%Ez", "{{ run_started_at }}"))
)

SELECT
  charge_id, -- Primary key
  product_id, -- Primary key
  product_name,
  order_id,
  charge_type,
  charge_change_state,
  monthly_recurring_revenue,
  effective_start_date,
  effective_end_date,
  charged_through_date
FROM ordered_changes
WHERE charge_version = latest_charge_for_product
