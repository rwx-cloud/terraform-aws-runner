# Basic example

Grants RWX permission to manage self-hosted runners in a single AWS account and
region.

Replace `label`, `external_id`, `rwx_account_id`, `subnet_ids`, and
`security_group_ids` with the values you configured for your self-hosted runner
at [cloud.rwx.com](https://cloud.rwx.com), then:

```console
terraform init
terraform apply
```
