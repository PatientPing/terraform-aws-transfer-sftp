output "custom_fqdn" {
  value = aws_route53_record.sftp.fqdn
}

output "bucket" {
  value = aws_s3_bucket.sftp_transfer.bucket
}

