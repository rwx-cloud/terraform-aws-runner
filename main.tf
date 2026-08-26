data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  ec2_arn_prefix = "arn:aws:ec2:${local.region}:${local.account_id}"

  # RWX tags every resource it creates in this account with this key, which is
  # what lets the policy below scope mutations to RWX-managed resources.
  managed_tag_key = "rwx:managed"

  request_tag_condition = {
    StringEquals = { "aws:RequestTag/${local.managed_tag_key}" = "true" }
  }
  resource_tag_condition = {
    StringEquals = { "ec2:ResourceTag/${local.managed_tag_key}" = "true" }
  }

  tags = var.tags
}

resource "aws_iam_role" "provisioning" {
  name        = "rwx-provisioning-${var.label}"
  description = "Allows RWX to provision and tear down self-hosted runners in this account."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.rwx_account_id}:root" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "provisioning" {
  name = "rwx-provisioning"
  role = aws_iam_role.provisioning.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateInstancesMustBeTagged"
        Effect = "Allow"
        Action = ["ec2:RunInstances", "ec2:CreateFleet"]
        Resource = [
          "${local.ec2_arn_prefix}:fleet/*",
          "${local.ec2_arn_prefix}:instance/*",
          "${local.ec2_arn_prefix}:volume/*",
          "${local.ec2_arn_prefix}:network-interface/*",
        ]
        Condition = local.request_tag_condition
      },
      {
        # Resources that RunInstances and CreateFleet reference rather than
        # create, so they carry no request tags of their own.
        Sid    = "ReferencedResourcesNoTagRequired"
        Effect = "Allow"
        Action = ["ec2:RunInstances", "ec2:CreateFleet"]
        Resource = concat(
          # Subnets and security groups are pinned to the ones configured for this runner.
          [for id in var.subnet_ids : "${local.ec2_arn_prefix}:subnet/${id}"],
          [for id in var.security_group_ids : "${local.ec2_arn_prefix}:security-group/${id}"],
          [
            "${local.ec2_arn_prefix}:launch-template/*",
            # AMIs and their backing snapshots are owned by RWX's account and shared into this one.
            "arn:aws:ec2:${local.region}::image/*",
            "arn:aws:ec2:${local.region}::snapshot/*",
          ],
        )
      },
      {
        Sid       = "CreateVolumesMustBeTagged"
        Effect    = "Allow"
        Action    = "ec2:CreateVolume"
        Resource  = "${local.ec2_arn_prefix}:volume/*"
        Condition = local.request_tag_condition
      },
      {
        Sid      = "TagOnlyAtCreateTime"
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "${local.ec2_arn_prefix}:*/*"
        Condition = {
          StringEquals = {
            "ec2:CreateAction" = ["RunInstances", "CreateFleet", "CreateVolume", "CreateLaunchTemplate"]
          }
        }
      },
      {
        Sid       = "TagOurResourcesAfterCreation"
        Effect    = "Allow"
        Action    = "ec2:CreateTags"
        Resource  = "${local.ec2_arn_prefix}:instance/*"
        Condition = local.resource_tag_condition
      },
      {
        Sid       = "CreateLaunchTemplateMustBeTagged"
        Effect    = "Allow"
        Action    = "ec2:CreateLaunchTemplate"
        Resource  = "${local.ec2_arn_prefix}:launch-template/*"
        Condition = local.request_tag_condition
      },
      {
        Sid       = "MutateOnlyOurLaunchTemplates"
        Effect    = "Allow"
        Action    = ["ec2:CreateLaunchTemplateVersion", "ec2:ModifyLaunchTemplate", "ec2:DeleteLaunchTemplate"]
        Resource  = "${local.ec2_arn_prefix}:launch-template/*"
        Condition = local.resource_tag_condition
      },
      {
        Sid       = "MutateOnlyOurResources"
        Effect    = "Allow"
        Action    = ["ec2:TerminateInstances", "ec2:StopInstances", "ec2:StartInstances", "ec2:DeleteTags"]
        Resource  = "${local.ec2_arn_prefix}:instance/*"
        Condition = local.resource_tag_condition
      },
      {
        Sid       = "MutateOnlyOurVolumes"
        Effect    = "Allow"
        Action    = ["ec2:AttachVolume", "ec2:DetachVolume", "ec2:DeleteVolume"]
        Resource  = ["${local.ec2_arn_prefix}:instance/*", "${local.ec2_arn_prefix}:volume/*"]
        Condition = local.resource_tag_condition
      },
      {
        Sid       = "ModifyOnlyOurInstances"
        Effect    = "Allow"
        Action    = ["ec2:ModifyInstanceAttribute", "ec2:ModifyInstanceCpuOptions"]
        Resource  = "${local.ec2_arn_prefix}:instance/*"
        Condition = local.resource_tag_condition
      },
      {
        Sid    = "ReadOnlyCannotBeScoped"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeFleets",
          "ec2:DescribeFleetInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeVolumes",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeImages",
        ]
        Resource = "*"
      },
      {
        Sid       = "PassRunnerProfileOnly"
        Effect    = "Allow"
        Action    = "iam:PassRole"
        Resource  = aws_iam_role.runner.arn
        Condition = { StringEquals = { "iam:PassedToService" = "ec2.amazonaws.com" } }
      },
    ]
  })
}

resource "aws_iam_role" "runner" {
  name        = "rwx-runner-${var.label}"
  description = "Identity that RWX self-hosted runner instances run as."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags
}

resource "aws_iam_instance_profile" "runner" {
  name = "rwx-runner-${var.label}"
  role = aws_iam_role.runner.name

  tags = local.tags
}
