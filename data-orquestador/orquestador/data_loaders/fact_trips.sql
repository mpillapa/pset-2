-- Docs: https://docs.mage.ai/guides/sql-blocks
DROP TABLE IF EXISTS clean.fact_trips CASCADE;

CREATE TABLE clean.fact_trips AS
SELECT 

    ROW_NUMBER() OVER() AS trip_id,


    CAST(NULLIF(vendorid, 'nan') AS INTEGER) AS vendor_id,
    CAST(NULLIF(payment_type, 'nan') AS INTEGER) AS payment_id,
    CAST(NULLIF(pulocationid, 'nan') AS INTEGER) AS pickup_location_id,
    CAST(NULLIF(dolocationid, 'nan') AS INTEGER) AS dropoff_location_id,


    CAST(NULLIF(tpep_pickup_datetime, 'nan') AS TIMESTAMP) AS pickup_datetime,
    CAST(NULLIF(tpep_dropoff_datetime, 'nan') AS TIMESTAMP) AS dropoff_datetime,


    CAST(NULLIF(passenger_count, 'nan') AS NUMERIC)::INTEGER AS passenger_count,
    CAST(NULLIF(trip_distance, 'nan') AS NUMERIC) AS trip_distance,
    CAST(NULLIF(fare_amount, 'nan') AS NUMERIC) AS fare_amount,
    CAST(NULLIF(tip_amount, 'nan') AS NUMERIC) AS tip_amount,
    CAST(NULLIF(tolls_amount, 'nan') AS NUMERIC) AS tolls_amount,
    CAST(NULLIF(total_amount, 'nan') AS NUMERIC) AS total_amount,


    EXTRACT(EPOCH FROM (
        CAST(NULLIF(tpep_dropoff_datetime, 'nan') AS TIMESTAMP) - 
        CAST(NULLIF(tpep_pickup_datetime, 'nan') AS TIMESTAMP)
    ))/60 AS trip_duration_minutes

FROM raw.ny_taxi_trips


WHERE 
    
    tpep_pickup_datetime IS NOT NULL AND tpep_pickup_datetime != 'nan'
    AND tpep_dropoff_datetime IS NOT NULL AND tpep_dropoff_datetime != 'nan'
    
    
    AND CAST(NULLIF(tpep_dropoff_datetime, 'nan') AS TIMESTAMP) > CAST(NULLIF(tpep_pickup_datetime, 'nan') AS TIMESTAMP)
    
    -- Validaciones lógicas de negocio
    AND CAST(NULLIF(trip_distance, 'nan') AS NUMERIC) > 0      
    AND CAST(NULLIF(total_amount, 'nan') AS NUMERIC) >= 0      
    AND CAST(NULLIF(passenger_count, 'nan') AS NUMERIC)::INTEGER > 0 
    
    
    AND EXTRACT(YEAR FROM CAST(NULLIF(tpep_pickup_datetime, 'nan') AS TIMESTAMP)) BETWEEN 2015 AND 2025;