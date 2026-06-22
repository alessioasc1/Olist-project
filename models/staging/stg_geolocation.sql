    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        AVG(TRY_TO_DOUBLE(geolocation_lat)) AS latitude,
        AVG(TRY_TO_DOUBLE(geolocation_lng)) AS longitude,
        UPPER(TRIM(ANY_VALUE(geolocation_city))) AS city,
        UPPER(TRIM(ANY_VALUE(geolocation_state))) AS state,
        MAX(CAST(_loaded_at AS TIMESTAMP)) AS loaded_at
    FROM {{ source('olist_raw', 'GEOLOCATION') }}
    WHERE TRY_TO_DOUBLE(geolocation_lat) BETWEEN -34 AND 5
      AND TRY_TO_DOUBLE(geolocation_lng) BETWEEN -74 AND -34
    GROUP BY geolocation_zip_code_prefix