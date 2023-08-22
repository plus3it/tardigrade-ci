"""Run Terraform plan/apply against each set of Terraform test files."""

import copy
import glob
import json
import os
from pathlib import Path

import hcl2
import pytest
import tftest

AWS_DEFAULT_REGION = os.getenv("AWS_DEFAULT_REGION", default="us-east-1")
MOCKSTACK_HOST = os.getenv("MOCKSTACK_HOST", default="localhost")
MOCKSTACK_PORT = "4566"
MOTO_PORT = "4615"

MOCKSTACK_TF_PROVIDER_OVERRIDE = "tardigrade_ci_provider_override.tf.json"


@pytest.fixture(scope="function")
def tf_test_object(is_mock, tf_dir, tmp_path, aws_provider_override):
    """Return function that will create tf_test object using given subdir."""

    def parse_tf_module(tf_module):
        """Parse all tf files in directory."""
        tf_objects = []
        for file in glob.glob(f"{tf_module}/*.tf"):
            with open(file, "r", encoding="utf8") as handle:
                tf_objects.append(hcl2.load(handle))
        return tf_objects

    def tf_aws_providers(tf_object):
        """Return list of aws provider configs."""
        aws_providers = []
        for provider in tf_object.get("provider", []):
            if "aws" in provider:
                aws_providers.append(provider["aws"])
        return aws_providers

    def write_file(path, content):
        """Write content to path."""
        path = tmp_path / MOCKSTACK_TF_PROVIDER_OVERRIDE
        path.write_text(content)
        return str(path)

    def make_tf_test(tf_module):
        """Return a TerraformTest object for given module."""
        tf_test = tftest.TerraformTest(tf_module, basedir=str(tf_dir), env=None)
        extra_files = []

        # Create an override file that contain endpoints for all the services in use
        if is_mock:
            current_dir = Path(__file__).resolve().parent

            # Get the terraform objects from the test module
            tf_objects = parse_tf_module(tf_dir / tf_module)

            mock_provider = copy.deepcopy(aws_provider_override)
            mock_aws_provider = mock_provider["provider"]["aws"][0]

            # Get the aws providers from the terraform objects
            aws_providers = []
            for tf_object in tf_objects:
                aws_providers.extend(tf_aws_providers(tf_object))

            # For all aws provider blocks that contain an "alias" attribute,
            # add a mock aws provider config with that alias
            for provider in aws_providers:
                if "alias" in provider:
                    mock_provider["provider"]["aws"].append(
                        {
                            **mock_aws_provider,
                            **{"alias": provider["alias"]},
                        }
                    )

            tf_provider_path = Path(current_dir / MOCKSTACK_TF_PROVIDER_OVERRIDE)
            extra_files.append(
                write_file(tf_provider_path, json.dumps(mock_provider, indent=4))
            )
        tf_test.setup(extra_files=extra_files, upgrade=True, cleanup_on_exit=False)
        return tf_test

    return make_tf_test


@pytest.fixture(scope="function")
def aws_provider_override(only_moto):
    """Return override config for mock aws provider."""
    mockstack_port = MOTO_PORT if only_moto else MOCKSTACK_PORT
    mockstack_endpoint = f"http://{MOCKSTACK_HOST}:{mockstack_port}"
    moto_endpoint = f"http://{MOCKSTACK_HOST}:{MOTO_PORT}"
    return {
        "provider": {
            "aws": [
                {
                    "skip_credentials_validation": True,
                    "skip_metadata_api_check": True,
                    "skip_region_validation": True,
                    "skip_requesting_account_id": True,
                    "s3_use_path_style": True,
                    "endpoints": {
                        # Supported by localstack community
                        "apigateway": mockstack_endpoint,
                        "acm": mockstack_endpoint,
                        "cloudformation": mockstack_endpoint,
                        "cloudwatch": mockstack_endpoint,
                        "configservice": mockstack_endpoint,
                        "dynamodb": mockstack_endpoint,
                        "ec2": mockstack_endpoint,
                        "elasticsearch": mockstack_endpoint,
                        "events": mockstack_endpoint,
                        "firehose": mockstack_endpoint,
                        "iam": mockstack_endpoint,
                        "kinesis": mockstack_endpoint,
                        "kms": mockstack_endpoint,
                        "lambda": mockstack_endpoint,
                        "logs": mockstack_endpoint,
                        "opensearch": mockstack_endpoint,
                        "redshift": mockstack_endpoint,
                        "resourcegroups": mockstack_endpoint,
                        "resourcegroupstaggingapi": mockstack_endpoint,
                        "route53": mockstack_endpoint,
                        "route53resolver": mockstack_endpoint,
                        "s3": mockstack_endpoint,
                        "s3control": mockstack_endpoint,
                        "sfn": mockstack_endpoint,  # stepfunctions
                        "secretsmanager": mockstack_endpoint,
                        "ses": mockstack_endpoint,
                        "sns": mockstack_endpoint,
                        "sqs": mockstack_endpoint,
                        "ssm": mockstack_endpoint,
                        "sts": mockstack_endpoint,
                        "swf": mockstack_endpoint,
                        "transcribe": mockstack_endpoint,
                        # Try moto for everything else
                        "accessanalyzer": moto_endpoint,
                        "account": moto_endpoint,
                        "acmpca": moto_endpoint,
                        "amp": moto_endpoint,
                        "amplify": moto_endpoint,
                        "apigatewayv2": moto_endpoint,
                        "appautoscaling": moto_endpoint,
                        "appconfig": moto_endpoint,
                        "appflow": moto_endpoint,
                        "appintegrations": moto_endpoint,
                        "applicationinsights": moto_endpoint,
                        "appmesh": moto_endpoint,
                        "apprunner": moto_endpoint,
                        "appstream": moto_endpoint,
                        "appsync": moto_endpoint,
                        "athena": moto_endpoint,
                        "auditmanager": moto_endpoint,
                        "autoscaling": moto_endpoint,
                        "autoscalingplans": moto_endpoint,
                        "backup": moto_endpoint,
                        "batch": moto_endpoint,
                        "budgets": moto_endpoint,
                        "ce": moto_endpoint,
                        "chime": moto_endpoint,
                        "cloud9": moto_endpoint,
                        "cloudcontrol": moto_endpoint,
                        "cloudfront": moto_endpoint,
                        "cloudhsmv2": moto_endpoint,
                        "cloudsearch": moto_endpoint,
                        "cloudtrail": moto_endpoint,
                        "codeartifact": moto_endpoint,
                        "codebuild": moto_endpoint,
                        "codecommit": moto_endpoint,
                        "codegurureviewer": moto_endpoint,
                        "codepipeline": moto_endpoint,
                        "codestarconnections": moto_endpoint,
                        "codestarnotifications": moto_endpoint,
                        "cognitoidentity": moto_endpoint,
                        "cognitoidp": moto_endpoint,
                        "comprehend": moto_endpoint,
                        "computeoptimizer": moto_endpoint,
                        "connect": moto_endpoint,
                        "controltower": moto_endpoint,
                        "cur": moto_endpoint,
                        "dataexchange": moto_endpoint,
                        "datapipeline": moto_endpoint,
                        "datasync": moto_endpoint,
                        "dax": moto_endpoint,
                        "deploy": moto_endpoint,
                        "detective": moto_endpoint,
                        "devicefarm": moto_endpoint,
                        "directconnect": moto_endpoint,
                        "dlm": moto_endpoint,
                        "dms": moto_endpoint,
                        "docdb": moto_endpoint,
                        "ds": moto_endpoint,
                        "ecr": moto_endpoint,
                        "ecrpublic": moto_endpoint,
                        "ecs": moto_endpoint,
                        "efs": moto_endpoint,
                        "eks": moto_endpoint,
                        "elasticache": moto_endpoint,
                        "elasticbeanstalk": moto_endpoint,
                        "elastictranscoder": moto_endpoint,
                        "elb": moto_endpoint,
                        "elbv2": moto_endpoint,
                        "emr": moto_endpoint,
                        "emrcontainers": moto_endpoint,
                        "emrserverless": moto_endpoint,
                        "evidently": moto_endpoint,
                        "finspace": moto_endpoint,
                        "fis": moto_endpoint,
                        "fms": moto_endpoint,
                        "fsx": moto_endpoint,
                        "gamelift": moto_endpoint,
                        "glacier": moto_endpoint,
                        "globalaccelerator": moto_endpoint,
                        "glue": moto_endpoint,
                        "grafana": moto_endpoint,
                        "greengrass": moto_endpoint,
                        "guardduty": moto_endpoint,
                        "healthlake": moto_endpoint,
                        "identitystore": moto_endpoint,
                        "imagebuilder": moto_endpoint,
                        "inspector": moto_endpoint,
                        "inspector2": moto_endpoint,
                        "iot": moto_endpoint,
                        "iotanalytics": moto_endpoint,
                        "iotevents": moto_endpoint,
                        "ivs": moto_endpoint,
                        "ivschat": moto_endpoint,
                        "kafka": moto_endpoint,
                        "kafkaconnect": moto_endpoint,
                        "kendra": moto_endpoint,
                        "keyspaces": moto_endpoint,
                        "kinesisanalytics": moto_endpoint,
                        "kinesisanalyticsv2": moto_endpoint,
                        "kinesisvideo": moto_endpoint,
                        "lakeformation": moto_endpoint,
                        "lexmodels": moto_endpoint,
                        "licensemanager": moto_endpoint,
                        "lightsail": moto_endpoint,
                        "location": moto_endpoint,
                        "macie2": moto_endpoint,
                        "mediaconnect": moto_endpoint,
                        "mediaconvert": moto_endpoint,
                        "medialive": moto_endpoint,
                        "mediapackage": moto_endpoint,
                        "mediastore": moto_endpoint,
                        "memorydb": moto_endpoint,
                        "mq": moto_endpoint,
                        "mwaa": moto_endpoint,
                        "neptune": moto_endpoint,
                        "networkfirewall": moto_endpoint,
                        "networkmanager": moto_endpoint,
                        "opensearchserverless": moto_endpoint,
                        "opsworks": moto_endpoint,
                        "organizations": moto_endpoint,
                        "outposts": moto_endpoint,
                        "pinpoint": moto_endpoint,
                        "pipes": moto_endpoint,
                        "pricing": moto_endpoint,
                        "qldb": moto_endpoint,
                        "quicksight": moto_endpoint,
                        "ram": moto_endpoint,
                        "rbin": moto_endpoint,
                        "rds": moto_endpoint,
                        "redshiftdata": moto_endpoint,
                        "redshiftserverless": moto_endpoint,
                        "resourceexplorer2": moto_endpoint,
                        "rolesanywhere": moto_endpoint,
                        "route53domains": moto_endpoint,
                        "route53recoverycontrolconfig": moto_endpoint,
                        "route53recoveryreadiness": moto_endpoint,
                        "rum": moto_endpoint,
                        "s3outposts": moto_endpoint,
                        "sagemaker": moto_endpoint,
                        "scheduler": moto_endpoint,
                        "schemas": moto_endpoint,
                        "securityhub": moto_endpoint,
                        "serverlessrepo": moto_endpoint,
                        "servicecatalog": moto_endpoint,
                        "servicediscovery": moto_endpoint,
                        "servicequotas": moto_endpoint,
                        "sesv2": moto_endpoint,
                        "shield": moto_endpoint,
                        "signer": moto_endpoint,
                        "simpledb": moto_endpoint,
                        "ssmcontacts": moto_endpoint,
                        "ssmincidents": moto_endpoint,
                        "ssoadmin": moto_endpoint,
                        "storagegateway": moto_endpoint,
                        "synthetics": moto_endpoint,
                        "timestreamwrite": moto_endpoint,
                        "transfer": moto_endpoint,
                        "waf": moto_endpoint,
                        "wafregional": moto_endpoint,
                        "wafv2": moto_endpoint,
                        "worklink": moto_endpoint,
                        "workspaces": moto_endpoint,
                        "xray": moto_endpoint,
                    },
                }
            ]
        }
    }


def test_modules(subdir, monkeypatch, tf_test_object):
    """Run plan/apply against a Terraform module found in tests subdir."""
    monkeypatch.setenv("AWS_DEFAULT_REGION", AWS_DEFAULT_REGION)

    tf_test = None
    prereq_tf_test = None
    try:
        # Run the Terraform module in "prereq" before executing the test
        # itself.
        if Path(subdir / "prereq").exists():
            prereq_tf_test = tf_test_object(str(subdir / "prereq"))
            prereq_tf_test.apply()

        # Apply the plan for the module under test.
        tf_test = tf_test_object(str(subdir))
        tf_test.apply()
    except tftest.TerraformTestError as exc:
        pytest.exit(
            reason=f"catastropic error running Terraform 'apply': {exc}",
            returncode=1,
        )
    finally:
        # Destroy the resources for the module under test, then destroy the
        # "prereq" resources, if a "prereq" subdirectory exists.
        if tf_test:
            tf_test.destroy()
        if prereq_tf_test:
            prereq_tf_test.destroy()
