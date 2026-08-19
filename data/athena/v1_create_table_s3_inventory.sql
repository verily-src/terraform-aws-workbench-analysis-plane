/*
Definition: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory-athena-query.html
*/

CREATE EXTERNAL TABLE IF NOT EXISTS ${table_s3_inventory} (
    bucket STRING,
    key STRING,
    size BIGINT
)

PARTITIONED BY (
    dt STRING
)

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'

STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.SymlinkTextInputFormat'
          OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat'

LOCATION ${s3_path}
