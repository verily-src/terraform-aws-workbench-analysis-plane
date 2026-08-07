PREPARE cost_report_s3_storage_folder FROM

UNLOAD (
    WITH bucket_report as (
        SELECT line_item_usage_type AS usage_type,
               SUM(line_item_usage_amount) AS total_usage,
               SUM(line_item_unblended_cost) AS total_cost,
               CAST(line_item_usage_start_date AS DATE) AS dt
        FROM ${table_cost_usage_report}
        WHERE product_servicecode = 'AmazonS3' AND
              line_item_resource_id = ? AND
              CAST(line_item_usage_start_date AS DATE) = DATE_PARSE(?, '%Y:%m:%d')
        GROUP BY line_item_usage_type,
                 CAST(line_item_usage_start_date AS DATE)
    )

    SELECT resource_key,
           'AWS_S3_STORAGE_FOLDER' AS resource_type,
           cost_type,
           SUM(resource_cost) AS resource_cost,
           dt

    FROM (
        (SELECT storage.resource_key,
                'Storage' AS cost_type,
                bucket_report.total_cost * (storage.folder_bytes / (bucket_report.total_usage * POWER(10, 9))) AS resource_cost,
                storage.dt

         FROM bucket_report,
            (SELECT SUBSTR(key, 1, STRPOS(key, '/')) AS resource_key,
                    CAST(sum(size) AS DOUBLE) AS folder_bytes,
                    CAST(DATE_PARSE(dt, '%Y-%m-%d-%H-%i') AS DATE) AS dt

             FROM ${table_s3_inventory}
             WHERE size > 0 AND
                   CAST(DATE_PARSE(dt, '%Y-%m-%d-%H-%i') AS DATE) = DATE_PARSE(?, '%Y:%m:%d')
             GROUP BY SUBSTR(key, 1, STRPOS(key, '/')),
                      dt
            ) AS storage
         WHERE bucket_report.usage_type LIKE '%TimedStorage-%' AND
               bucket_report.dt = storage.dt)

        UNION

        (SELECT requests.resource_key,
                'API Requests' AS cost_type,
                bucket_report.total_cost * (requests.folder_requests / bucket_report.total_usage) AS resource_cost,
                requests.dt
         FROM bucket_report,
            (SELECT folder_name AS resource_key,
                    COUNT(*) AS folder_requests,
                    CAST(dt AS DATE) AS dt
             FROM ${table_s3_data_requests}
             WHERE CAST(dt AS DATE) = DATE_PARSE(?, '%Y:%m:%d')
             GROUP BY folder_name,
                      dt
            ) AS requests
         WHERE bucket_report.usage_type LIKE '%Requests-%' AND
               bucket_report.dt = requests.dt)

        UNION

        (SELECT data_in.resource_key,
                'Data Transfer (In)' AS cost_type,
                bucket_report.total_cost * (data_in.folder_data_in / bucket_report.total_usage) AS resource_cost,
                data_in.dt
         FROM bucket_report,
            (SELECT folder_name AS resource_key,
                    SUM(bytes_in) AS folder_data_in,
                    CAST(dt AS DATE) AS dt
             FROM ${table_s3_data_requests}
             WHERE CAST(dt AS DATE) = DATE_PARSE(?, '%Y:%m:%d')
            GROUP BY folder_name,
                     dt
            ) AS data_in
         WHERE bucket_report.usage_type LIKE '%DataTransfer-In%' AND
               bucket_report.dt = data_in.dt)

        UNION

        (SELECT data_out.resource_key,
                'Data Transfer (Out)' AS cost_type,
                bucket_report.total_cost * (data_out.folder_data_out / bucket_report.total_usage) AS resource_cost,
                data_out.dt
         FROM bucket_report,
            (SELECT folder_name AS resource_key,
                    SUM(bytes_out) AS folder_data_out,
                    CAST(dt AS DATE) AS dt
             FROM ${table_s3_data_requests}
             WHERE CAST(dt AS DATE) = DATE_PARSE(?, '%Y:%m:%d')
             GROUP BY folder_name,
                      dt
            ) AS data_out
         WHERE bucket_report.usage_type LIKE '%DataTransfer-Out%' AND
	           bucket_report.dt = data_out.dt)
    )

    GROUP BY resource_key, cost_type, dt
)

TO ${s3_path}

WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['dt']
)

/*
TODO(BENCH-1771): refactor this query as part of multi-region support
-- Comments should be placed after the query in prepared statements --
Determines total costs incurred by a S3 Storage Folder
    - Parameters:
        * bucket_name
        * report_date (YYYY:MM:DD) for the bucket
        * report_date (YYYY:MM:DD) for folder storage
        * report_date (YYYY:MM:DD) for folder requests
        * report_date (YYYY:MM:DD) for folder data-in
        * report_date (YYYY:MM:DD) for folder data-out
    - Input: cost_usage_report (run at least 1x/day), s3_inventory (run 1x/day), s3_data_requests
    - Output: Parquet files in S3

Output columns
    - resource_key: s3_data_requests.folder_name
    - resource_type: set to 'AWS_S3_STORAGE_FOLDER'
    - cost_type: from cost_usage_report.product_product_family
        * 'Storage' (line_item_usage_type: 'region-TimedStorage-*')
        * 'API Requests' (line_item_usage_type: 'region-Requests-*')
        * 'Data Transfer (In)' (line_item_usage_type: 'region-DataTransfer-In-*')
        * 'Data Transfer (Out)' (line_item_usage_type: 'region-DataTransfer-Out-*')
    - resource_cost: portion of sum(cost_usage_report.line_item_unblended_cost)
        * Storage
            ~ cost_usage_report: Cost of bucket storage = sum(line_item_unblended_cost)
            ~ cost_usage_report: Size of bucket storage (GB) = sum(line_item_usage_amount)
            ~ s3_inventory: Size of folder storage (Bytes) = sum(size of all objects in folder)
        * API Requests
            ~ cost_usage_report: Cost of bucket requests = sum(line_item_unblended_cost)
            ~ cost_usage_report: Count of bucket requests = sum(line_item_usage_amount)
            ~ s3_data_requests: Count of folder requests = sum(count of all requests for folder)
        * Data Transfer (In) / Data Transfer (Out)
            ~ cost_usage_report: Cost of bucket data = sum(line_item_unblended_cost)
            ~ cost_usage_report: Volume of bucket data = sum(line_item_usage_amount)
            ~ s3_data_requests: Volume of folder data = sum(count of all requests for folder)
    - dt(partition): cost_usage_report.line_item_usage_start_date, s3_inventory.dt, s3_data_requests.dt

References
    - API Requests / Data Transfer (In) / Data Transfer (Out)
        * https://docs.aws.amazon.com/AmazonS3/latest/userguide/aws-usage-report-understand.html
*/
