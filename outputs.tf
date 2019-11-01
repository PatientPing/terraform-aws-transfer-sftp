output "bucket" {
  value = aws_s3_bucket.sftp_transfer[0]
}

output "bucket_logging" {
  value = aws_s3_bucket.sftp_transfer_s3_logging[0]
}

output "custom_dns_record" {
  value = aws_route53_record.sftp[0]
}

