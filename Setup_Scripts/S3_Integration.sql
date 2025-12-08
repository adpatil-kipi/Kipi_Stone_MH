CREATE STORAGE INTEGRATION kipi_stone_s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::217352460281:role/SnowflakeStorageRole'
  STORAGE_ALLOWED_LOCATIONS = ('s3://kipi-stone-mh-data--usw2-az1--x-s3/MH_Data_Files/');

DESC INTEGRATION kipi_stone_s3_integration; --Take out External ID and IAM User ARN

CREATE OR REPLACE STAGE kipi_stone_s3_external_stage
  STORAGE_INTEGRATION = kipi_stone_s3_integration
  URL = 's3://kipi-stone-mh-data--usw2-az1--x-s3/MH_Data_Files/'
  FILE_FORMAT = MH_DEV_DB.MH_RAW.MH_FILE_FORMAT ;