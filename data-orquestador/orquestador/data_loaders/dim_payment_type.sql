-- Docs: https://docs.mage.ai/guides/sql-blocks

CREATE SCHEMA IF NOT EXISTS clean;


DROP TABLE IF EXISTS clean.dim_payment_type CASCADE;


CREATE TABLE clean.dim_payment_type AS
SELECT DISTINCT 
    CAST(NULLIF(payment_type, 'nan') AS INTEGER) AS payment_id,
    CASE 
        WHEN payment_type = '1' THEN 'Credit card'
        WHEN payment_type = '2' THEN 'Cash'
        WHEN payment_type = '3' THEN 'No charge'
        WHEN payment_type = '4' THEN 'Dispute'
        WHEN payment_type = '5' THEN 'Unknown'
        WHEN payment_type = '6' THEN 'Voided trip'
        ELSE 'Not recorded'
    END AS payment_description
FROM raw.ny_taxi_trips
WHERE payment_type IS NOT NULL AND payment_type != 'nan';