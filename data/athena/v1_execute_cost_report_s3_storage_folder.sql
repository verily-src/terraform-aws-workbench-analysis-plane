/*
params:
    - bucket_name
    - report_date (YYYY:MM:DD) for the bucket
    - report_date (YYYY:MM:DD) for folder storage
    - report_date (YYYY:MM:DD) for folder requests
    - report_date (YYYY:MM:DD) for folder data-in
    - report_date (YYYY:MM:DD) for folder data-out
(using 'YYYY-MM-DD' results in mathematical operation)
*/

EXECUTE cost_report_s3_storage_folder USING ?, ?, ?, ?, ?, ?
