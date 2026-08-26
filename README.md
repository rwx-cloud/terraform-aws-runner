# terraform-aws-runner

Grants [RWX](https://www.rwx.com) permission to provision self-hosted runners in
your AWS account. Contact [RWX support](https://www.rwx.com/support) to enable
support for self-hosted runners.

The module creates two IAM roles and nothing else. It does not create VPCs,
subnets, security groups, or EC2 instances — RWX launches instances into the
network you already have, using the subnets and security groups you specify.

- **Provisioning role** (`rwx-provisioning-<label>`) — RWX assumes this role to
  launch, tag, and terminate runners. Its trust policy is pinned to your
  runner's external ID, and its permissions are scoped to the subnets and
  security groups you pass in, to AMIs that RWX shares with your account, and to
  resources carrying the `rwx:managed` tag.
- **Instance role** (`rwx-runner-<label>`) and matching instance profile — the
  identity your runner instances run as. It starts with no permissions; attach
  your own policies to grant builds access to your AWS resources.

## Usage

Contact [RWX support](https://www.rwx.com/support) to enable support for
self-hosted runners.

Create a self-hosted AWS runner at [cloud.rwx.com](https://cloud.rwx.com), then
apply this module with the values it shows you. For example:

```hcl
provider "aws" {
  region = "us-east-1"
}

module "rwx_runner" {
  source  = "rwx-cloud/runner/aws"
  version = "~> 1.0"

  rwx_self_hosted_runner_label       = "prod"
  rwx_self_hosted_runner_external_id = "8f4c1d92a7b3e5604fa8c2d19e0b7635"
  rwx_aws_account_id                 = "123456789012"
  subnet_ids                         = ["subnet-05f8a3c19d7e4b206"]
  security_group_ids                 = ["sg-0c2e91b7a4f36d508"]
}
```

The module has no provider block of its own, so it creates its resources in
whichever account and region the `aws` provider is configured for. That region
must match the region configured for the self-hosted runner configuration in RWX.

If your organization does not allow modules from the public registry, source it
from git instead. Version constraints are not available on git sources, so pin
an exact tag:

```hcl
module "rwx_runner" {
  source = "git::https://github.com/rwx-cloud/terraform-aws-runner.git?ref=v1.0.0"
  # ...
}
```

### Granting your builds access to other AWS resources

Attach policies to the instance role:

```hcl
resource "aws_iam_role_policy_attachment" "runner_ecr" {
  role       = module.rwx_runner.instance_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
```

## Upgrading

RWX occasionally releases new features that require permissions an older version of
this module did not grant. To upgrade, raise the `version` constraint and re-apply.

## Examples

- [Basic](https://github.com/rwx-cloud/terraform-aws-runner/tree/main/examples/basic) - A single runner in one account and region

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.provisioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.provisioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_rwx_aws_account_id"></a> [rwx\_aws\_account\_id](#input\_rwx\_aws\_account\_id) | RWX's AWS account ID, which the provisioning role's trust policy allows to assume it. Look it up on cloud.rwx.com. | `string` | n/a | yes |
| <a name="input_rwx_self_hosted_runner_external_id"></a> [rwx\_self\_hosted\_runner\_external\_id](#input\_rwx\_self\_hosted\_runner\_external\_id) | External ID that RWX generates for this self-hosted runner configuration; look it up on cloud.rwx.com. RWX presents it when assuming the provisioning role, which pins the trust policy to a single runner and guards against the confused deputy problem (https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html). | `string` | n/a | yes |
| <a name="input_rwx_self_hosted_runner_label"></a> [rwx\_self\_hosted\_runner\_label](#input\_rwx\_self\_hosted\_runner\_label) | Label of the self-hosted runner configuration on cloud.rwx.com. Set `runner.self-hosted` to this value in an RWX run definition to route tasks to this runner configuration. Also determines the names of the IAM roles this module creates. | `string` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security groups that RWX may attach to runner instances. The provisioning role is scoped to these security groups. | `list(string)` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets that RWX may launch runner instances into. The provisioning role is scoped to these subnets, so runners cannot be launched elsewhere in the account. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags applied to every resource this module creates. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_instance_profile_arn"></a> [instance\_profile\_arn](#output\_instance\_profile\_arn) | ARN of the instance profile attached to runner instances. |
| <a name="output_instance_role_arn"></a> [instance\_role\_arn](#output\_instance\_role\_arn) | ARN of the role that runner instances run as. Attach additional policies to it to grant your builds access to other AWS resources. |
| <a name="output_instance_role_name"></a> [instance\_role\_name](#output\_instance\_role\_name) | Name of the role that runner instances run as. |
| <a name="output_provisioning_role_arn"></a> [provisioning\_role\_arn](#output\_provisioning\_role\_arn) | ARN of the role RWX assumes to manage runners in this account. |
| <a name="output_provisioning_role_name"></a> [provisioning\_role\_name](#output\_provisioning\_role\_name) | Name of the role RWX assumes to manage runners in this account. |
<!-- END_TF_DOCS -->

## License

MIT. See [LICENSE](LICENSE).
