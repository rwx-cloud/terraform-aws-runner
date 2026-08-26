terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# The module creates its resources in whichever region and account this provider
# is configured for. It must match the region configured for the runner in RWX.
provider "aws" {
  region = "us-east-1"
}

# The label, external_id, and rwx_account_id values below are provided by RWX
# when you configure a self-hosted runner — copy them directly from the runner
# setup page at cloud.rwx.com. The subnet_ids and security_group_ids reference
# resources in your own AWS account.
module "rwx_runner" {
  source  = "rwx-cloud/runner/aws"
  version = "~> 1.0"

  label              = "prod"
  external_id        = "8f4c1d92a7b3e5604fa8c2d19e0b7635"
  rwx_account_id     = "123456789012"
  subnet_ids         = ["subnet-05f8a3c19d7e4b206"]
  security_group_ids = ["sg-0c2e91b7a4f36d508"]

  tags = {
    Team = "platform"
  }
}

output "provisioning_role_arn" {
  value = module.rwx_runner.provisioning_role_arn
}
