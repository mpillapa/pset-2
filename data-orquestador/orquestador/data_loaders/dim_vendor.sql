-- Docs: https://docs.mage.ai/guides/sql-blocks
DROP TABLE IF EXISTS clean.dim_vendor CASCADE;

CREATE TABLE clean.dim_vendor AS
SELECT DISTINCT 
    CAST(NULLIF(vendorid, 'nan') AS INTEGER) AS vendor_id,
    CASE 
        WHEN vendorid = '1' THEN 'Creative Mobile Technologies, LLC'
        WHEN vendorid = '2' THEN 'VeriFone Inc.'
        WHEN vendorid= '6' THEN 'Myle Technologies Inc'
        WHEN vendorid= '7' THEN 'Helix'
        ELSE 'Unknown'
    END AS vendor_name
FROM raw.ny_taxi_trips
WHERE vendorid IS NOT NULL AND vendorid != 'nan';