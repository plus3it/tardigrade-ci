provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_force_path_style         = true

  endpoints {
    apigateway       = "http://${var.mockstack_host}:${var.mockstack_port}"
    cloudformation   = "http://${var.mockstack_host}:${var.mockstack_port}"
    cloudwatch       = "http://${var.mockstack_host}:${var.mockstack_port}"
    cloudwatchevents = "http://${var.mockstack_host}:${var.mockstack_port}"
    cloudwatchlogs   = "http://${var.mockstack_host}:${var.mockstack_port}"
    dynamodb         = "http://${var.mockstack_host}:${var.mockstack_port}"
    ec2              = "http://${var.mockstack_host}:${var.mockstack_port}"
    firehose         = "http://${var.mockstack_host}:${var.mockstack_port}"
    iam              = "http://${var.mockstack_host}:${var.mockstack_port}"
    kinesis          = "http://${var.mockstack_host}:${var.mockstack_port}"
    kms              = "http://${var.mockstack_host}:${var.mockstack_port}"
    lambda           = "http://${var.mockstack_host}:${var.mockstack_port}"
    route53          = "http://${var.mockstack_host}:${var.mockstack_port}"
    redshift         = "http://${var.mockstack_host}:${var.mockstack_port}"
    s3               = "http://${var.mockstack_host}:${var.mockstack_port}"
    secretsmanager   = "http://${var.mockstack_host}:${var.mockstack_port}"
    ses              = "http://${var.mockstack_host}:${var.mockstack_port}"
    sns              = "http://${var.mockstack_host}:${var.mockstack_port}"
    sqs              = "http://${var.mockstack_host}:${var.mockstack_port}"
    ssm              = "http://${var.mockstack_host}:${var.mockstack_port}"
    stepfunctions    = "http://${var.mockstack_host}:${var.mockstack_port}"
    sts              = "http://${var.mockstack_host}:${var.mockstack_port}"
    configservice    = "http://${var.mockstack_host}:${var.moto_port}"
  }
}

variable "mockstack_host" {
  description = "Hostname for mock AWS endpoint"
  type        = string
  default     = "localhost"
}

variable "mockstack_port" {
  description = "Port for mock AWS endpoint"
  type        = string
  default     = "4566"
}

# Port 4615 was chosen to be used for moto because that port is used by
# LocalStack for the organizations service.  We'll piggyback onto that
# port for other moto-specific services.
variable "moto_port" {
  description = "Port for moto; for services not provided by LocalStack"
  type        = string
  default     = "4615"
}
