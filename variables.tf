variable "rwx_self_hosted_runner_label" {
  description = "Label of the self-hosted runner configuration on cloud.rwx.com. Set `runner.self-hosted` to this value in an RWX run definition to route tasks to this runner configuration. Also determines the names of the IAM roles this module creates."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$", var.rwx_self_hosted_runner_label))
    error_message = "The label may only contain letters, numbers, and dashes, and must start and end with a letter or number."
  }

  validation {
    condition     = length(var.rwx_self_hosted_runner_label) <= 47
    error_message = "The label must be 47 characters or fewer so that the generated IAM role names fit within IAM's 64 character limit."
  }
}

variable "rwx_self_hosted_runner_external_id" {
  description = "External ID that RWX generates for this self-hosted runner configuration; look it up on cloud.rwx.com. RWX presents it when assuming the provisioning role, which pins the trust policy to a single runner and guards against the confused deputy problem (https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html)."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.rwx_self_hosted_runner_external_id))
    error_message = "The external ID must be the 32 character hexadecimal value shown for this runner in RWX."
  }
}

variable "subnet_ids" {
  description = "Subnets that RWX may launch runner instances into. The provisioning role is scoped to these subnets, so runners cannot be launched elsewhere in your account."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID is required."
  }
}

variable "security_group_ids" {
  description = "Security groups that RWX may attach to runner instances. The provisioning role is scoped to these security groups."
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "At least one security group ID is required."
  }
}

variable "rwx_aws_account_id" {
  description = "RWX's AWS account ID, which the provisioning role's trust policy allows to assume it. Look it up on cloud.rwx.com."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.rwx_aws_account_id))
    error_message = "The RWX account ID must be a 12 digit AWS account ID."
  }
}

variable "tags" {
  description = "Additional tags applied to every resource this module creates."
  type        = map(string)
  default     = {}
}
