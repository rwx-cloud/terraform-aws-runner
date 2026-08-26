# Basic example

Grants RWX permission to manage self-hosted runners in a single AWS account and
region.

Replace `rwx_self_hosted_runner_label`, `rwx_self_hosted_runner_external_id`,
`rwx_aws_account_id`, `subnet_ids`, and
`security_group_ids` with the values you configured for your self-hosted runner
at [cloud.rwx.com](https://cloud.rwx.com), then:

```console
terraform init
terraform apply
```
