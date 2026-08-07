/*
Definition: https://docs.aws.amazon.com/athena/latest/ug/cloudtrail-logs.html#create-cloudtrail-table
*/

CREATE EXTERNAL TABLE IF NOT EXISTS ${table_s3_cloudtrail_logs} (
    eventtime STRING,
    eventname STRING,
    requestparameters STRING,
    additionaleventdata STRING,
    eventid STRING
)

PARTITIONED BY (
    region STRING,
    year STRING,
    month STRING,
    day STRING
)

ROW FORMAT SERDE 'org.apache.hive.hcatalog.data.JsonSerDe'

STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
          OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'

LOCATION ${s3_path}
