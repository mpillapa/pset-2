-- Docs: https://docs.mage.ai/guides/sql-blocks
DROP TABLE IF EXISTS clean.dim_location CASCADE;

CREATE TABLE clean.dim_location AS
SELECT DISTINCT CAST(NULLIF(location_id, 'nan') AS INTEGER) AS location_id
FROM (

    SELECT pulocationid AS location_id FROM raw.ny_taxi_trips
    UNION
    SELECT dolocationid AS location_id FROM raw.ny_taxi_trips
) AS locs
WHERE location_id IS NOT NULL AND location_id != 'nan';