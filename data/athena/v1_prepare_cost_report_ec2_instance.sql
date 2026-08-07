PREPARE cost_report_ec2_instance FROM

UNLOAD (
    SELECT resource_tags_user_resource_id AS resource_key,
           'AWS_EC2_INSTANCE' AS resource_type,
           product_product_family AS cost_type,
           SUM(line_item_unblended_cost) AS resource_cost,
           CAST(line_item_usage_start_date AS DATE) AS dt

    FROM ${table_cost_usage_report}

    WHERE resource_tags_user_resource_id <> '' AND
          product_servicecode = 'AmazonEC2' AND
          CAST(line_item_usage_start_date AS DATE) = DATE_PARSE(?, '%Y:%m:%d')

    GROUP BY resource_tags_user_resource_id,
             product_product_family,
             CAST(line_item_usage_start_date AS DATE)
)

TO ${s3_path}

WITH (
    format = 'PARQUET',
    partitioned_by = ARRAY['dt']
)

/*
-- Comments should be placed after the query in prepared statements --
Determines total costs incurred by a EC2 Instance
    - Parameters: report_date (YYYY:MM:DD)
    - Input: cost_usage_report (run at least 1x/day)
    - Output: Parquet files in S3

Output columns
    - resource_key: resource_tags_user_resource_id
    - resource_type: set to 'AWS_EC2_INSTANCE'
    - cost_type: from product_product_family
        * 'Compute Instance'
        * 'Storage'
        * 'CPU Credits'
    - resource_cost: sum(line_item_unblended_cost)
    - dt(partition): line_item_usage_start_date

References:
    - https://aws.amazon.com/ec2/pricing/on-demand/
*/
