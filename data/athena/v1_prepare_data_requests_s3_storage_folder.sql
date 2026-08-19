PREPARE data_requests_s3_storage_folder FROM

UNLOAD (
    SELECT eventid AS event_id,
           eventname AS event_name,
           CASE
                WHEN JSON_EXTRACT_SCALAR(requestparameters, '$.prefix') <> ''
                    THEN SUBSTR(JSON_EXTRACT_SCALAR(requestparameters, '$.prefix'), 1, STRPOS(JSON_EXTRACT_SCALAR(requestparameters, '$.prefix'), '/'))
                WHEN JSON_EXTRACT_SCALAR(requestparameters, '$.key') <> ''
                    THEN SUBSTR(JSON_EXTRACT_SCALAR(requestparameters, '$.key'), 1, STRPOS(JSON_EXTRACT_SCALAR(requestparameters, '$.key'), '/'))
           END AS folder_name,
           CAST(JSON_EXTRACT_SCALAR(additionaleventdata, '$.bytesTransferredIn') AS INT) AS bytes_in,
           CAST(JSON_EXTRACT_SCALAR(additionaleventdata, '$.bytesTransferredOut') AS INT) AS bytes_out,
           CAST(CAST(FROM_ISO8601_TIMESTAMP(eventtime) AS DATE) AS VARCHAR) AS dt

    FROM ${table_s3_cloudtrail_logs}

    WHERE REGEXP_LIKE(eventname, '(Object|Upload|Part)') AND
          (JSON_EXTRACT_SCALAR(requestparameters, '$.prefix') <> '' OR
           JSON_EXTRACT_SCALAR(requestparameters, '$.key') <> '') AND
          CAST(FROM_ISO8601_TIMESTAMP(eventtime) AS DATE) = DATE_PARSE(?, '%Y:%m:%d')
)

TO ${s3_path}

WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['dt']
)

/*
-- Comments should be placed after the query in prepared statements --
Calculate API requests & Data transfers of a S3 Storage Folder
    - Parameters:
        * report_date (YYYY:MM:DD)
    - Input: s3_cloudtrail_logs (running logs)
    - Output: Parquet files in S3

Output columns
    - event_id: eventid
    - event_name: eventname
        * only object-level events
    - folder_name: extracted from requestparameters (prefix or key, event specific)
    - bytes_in: extracted from additionaleventdata
    - bytes_out: extracted from additionaleventdata
    - dt(partition): eventtime

References
    - https://docs.aws.amazon.com/AmazonS3/latest/userguide/cloudtrail-request-identification.html
    - https://docs.aws.amazon.com/AmazonS3/latest/userguide/cloudtrail-logging-s3-info.html
*/
