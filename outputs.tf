output "bucket" {
  value = length(aws_s3_bucket.sftp_transfer) > 0 ? aws_s3_bucket.sftp_transfer[0] : null
}

output "bucket_logging" {
  value = length(aws_s3_bucket.sftp_transfer_s3_logging) > 0 ? aws_s3_bucket.sftp_transfer_s3_logging[0] : null
}

output "custom_dns_record" {
  value = length(aws_route53_record.sftp) > 0 ? aws_route53_record.sftp[0] : null
}

output "sftp" {
  value = aws_transfer_server.sftp
}