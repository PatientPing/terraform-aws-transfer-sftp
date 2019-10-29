variable "tags" {
  default = {}
}

variable "sftp_transfer_bucket_name" {
  description = "SFTP Transfer S3 Bucket Name"
}

variable "sftp_transfer_hostname" {
  description = "SFTP Transfer Hostname"
  default     = "sftp"
}

variable "sftp_users" {
  type = list(object({
    username = string
    key      = string
  }))
}

variable "sftp_s3_object_expiration_days" {
  description = "Number of days to keep objects in SFTP S3 bucket."
  type = number
  default = 30
}

variable "route53_zone_id" {
  description = "Route53 Zone ID for the custom DNS Record"
}