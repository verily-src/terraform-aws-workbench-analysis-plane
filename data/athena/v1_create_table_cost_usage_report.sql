/*
Definition: s3://<s3_bucket_name>>t/<s3_cost_usage_report>/<cost_usage_report>/<date-range>/<cost_usage_report>-create-table.sql
*/

CREATE EXTERNAL TABLE IF NOT EXISTS ${table_cost_usage_report} (
    identity_line_item_id STRING,
    identity_time_interval STRING,
    line_item_line_item_type STRING,
    line_item_usage_start_date TIMESTAMP,
    line_item_usage_end_date TIMESTAMP,
    line_item_product_code STRING,
    line_item_usage_type STRING,
    line_item_operation STRING,
    line_item_availability_zone STRING,
    line_item_resource_id STRING,
    line_item_usage_amount DOUBLE,
    line_item_currency_code STRING,
    line_item_unblended_rate STRING,
    line_item_unblended_cost DOUBLE,
    line_item_line_item_description STRING,
    product_product_family STRING,
    product_region_code STRING,
    product_servicecode STRING,
    product_usagetype STRING,
    resource_tags_user_user_i_d STRING,
    resource_tags_user_resource_id STRING,
    resource_tags_user_workspace_id STRING
)

PARTITIONED BY (
    year STRING,
    month STRING
)

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'

WITH SERDEPROPERTIES ('serialization.format' = '1')

LOCATION ${s3_path}
