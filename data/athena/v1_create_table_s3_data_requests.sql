/*
Definition: fields added on demand
*/

CREATE EXTERNAL TABLE IF NOT EXISTS ${table_s3_data_requests} (
    event_id STRING,
    event_name STRING,
    folder_name STRING,
    bytes_in INT,
    bytes_out INT
)

PARTITIONED BY (
    dt STRING
)

ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'

STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
          OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'

LOCATION ${s3_path}
