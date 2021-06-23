provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true

  endpoints {
    apigateway       = "http://localhost:5000"
    cloudformation   = "http://localhost:5000"
    cloudwatch       = "http://localhost:5000"
    cloudwatchevents = "http://localhost:5000"
    cloudwatchlogs   = "http://localhost:5000"
    dynamodb         = "http://localhost:5000"
    ec2              = "http://localhost:5000"
    firehose         = "http://localhost:5000"
    iam              = "http://localhost:5000"
    kinesis          = "http://localhost:5000"
    lambda           = "http://localhost:5000"
    route53          = "http://localhost:5000"
    redshift         = "http://localhost:5000"
    s3               = "http://localhost:5000"
    secretsmanager   = "http://localhost:5000"
    ses              = "http://localhost:5000"
    sns              = "http://localhost:5000"
    sqs              = "http://localhost:5000"
    ssm              = "http://localhost:5000"
    stepfunctions    = "http://localhost:5000"
    sts              = "http://localhost:5000"
  }
}
