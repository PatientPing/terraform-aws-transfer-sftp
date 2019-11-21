# terraform-aws-transfer-sftp

Terraform module to create and manage a single [Amazon Transfer for SFTP](https://aws.amazon.com/sftp/) backed by an S3 bucket.

By default the module creates and manages the S3 bucket but can use an existing externally managed bucket as well.

The module also manages users which can be granted read-only, write-only, and read-write access to their _home directories_.  Because AWS Transfer is backed by S3, what appear to be directories in SFTP are actually S3 prefixes which follow the pattern `<s3_bucket_name>/<home_dir_prefix><username>`.

## Input Variables

| Variable                            | Type        | Description                                                                    | Default      | Required |
| ----------------------------------- | ----------- |--------------------------------------------------------------------------------| ------------ | -------- |
| bucket_name                         | string      | SFTP Transfer S3 Bucket to transfer to/from                                    | none         | yes      |
| bucket_name_logging                 | string      | SFTP Transfer S3 Bucket to transfer to/from                                    | none         | yes      |
| custom_dns_domain                   | string      | If non-empty, domain name for custom DNS alias to sftp endpoint in Route53     | ""           | no       |
| custom_dns_hostname                 | string      | Route53 DNS alias hostname                                                     | "sftp"       | no       |
| home_dir_prefix                     | string      | Home directory prefix in S3 - <bucket_name>/<home_dir_prefix><username>        | "home/"      | no       |
| manage_bucket                       | bool        | If true, create/manage the S3 bucket in the module                             | True         | no       |
| s3_object_expiration_days           | number      | Expire objects in bucket if managed.                                           | null         | no       |
| tags                                | map(string) | Tags to assign to the buckets and roles                                        | {}           | no       |
| users_read_only                     | map(string) | A map of <username>:<ssh-key> for read-only users                              | {}           | no       |
| users_read_write                    | map(string) | A map of <username>:<ssh-key> for read-write users                             | {}           | no       |
| users_write_only                    | map(string) | A map of <username>:<ssh-key> for write-only users                             | {}           | no       |

## Output Variables

| Variable                            | Type                     | Description                                                             |
| ----------------------------------- | ------------------------ |------------------------------------------------------------------------ |
| bucket                              | aws_s3_bucket            | SFTP Transfer S3 bucket to transfer to/from                             |
| bucket_logging                      | aws_s3_bucket            | SFTP Transfer S3 logging bucket                                         |
| log_group                           | aws_cloudwatch_log_group | Transfer Server Cloudwatch log group                                    |
| custom_dns_record                   | aws_route53_record       | Custom DNS Route53 record                                               |
| sftp                                | aws_transfer_server      | Transfer Server for SFTP outputs                                        |


## Invocation Example

```
module "sftp" {
  source = "github.com/PatientPing/terraform-aws-transfer-sftp"

  bucket_name               = "sftp-transfer.infra-sandbox.s.patientping.net"
  bucket_name_logging       = "sftp-transfer-logging.infra-sandbox.s.patientping.net"
  custom_dns_domain         = data.terraform_remote_state.foundation.outputs.dns.name
  s3_object_expiration_days = 30

  users_write_only = {
    test1 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNxqJHP3VnYpX2ulEk4Lr0icTV/+6O3Jlv7hhWmfz4BfW1Q55CFmyJTwo336L2RYzM67r2kXtaoHDclfmWqFt+zulRdkEMVA+ofHj0wbl680t633kXakOuEHE3/tlPh/MnRBwM6VqAi3ZZhnMJ9R/+Bdulegfu0b9fwOpAE/s3e2XOXsGx6+1wzzLiUnEnvT2MoB/9KasU7pQvZTM5vwX4+tqyULjKUJ3U4e2r8LAXkEVy+Rq+5uhfVADi8qvtJPoEVui5EWfKCyTC9zvgaNoBs6/sK2h0BrKpCaaZ7dSywF9AyM36fZa/cMl2QNQitGfiywWuaHS78jsKmRSR5cyF",
    test2 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNxqJHP3VnYpX2ulEk4Lr0icTV/+6O3Jlv7hhWmfz4BfW1Q55CFmyJTwo336L2RYzM67r2kXtaoHDclfmWqFt+zulRdkEMVA+ofHj0wbl680t633kXakOuEHE3/tlPh/MnRBwM6VqAi3ZZhnMJ9R/+Bdulegfu0b9fwOpAE/s3e2XOXsGx6+1wzzLiUnEnvT2MoB/9KasU7pQvZTM5vwX4+tqyULjKUJ3U4e2r8LAXkEVy+Rq+5uhfVADi8qvtJPoEVui5EWfKCyTC9zvgaNoBs6/sK2h0BrKpCaaZ7dSywF9AyM36fZa/cMl2QNQitGfiywWuaHS78jsjdansfnoe"
  }
}
```

Reference:
https://docs.aws.amazon.com/transfer/latest/userguide/getting-started-server.html
https://aws.amazon.com/sftp/faqs/
