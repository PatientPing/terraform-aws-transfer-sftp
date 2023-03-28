resource "aws_transfer_server" "sftp" {
  logging_role = aws_iam_role.sftp_transfer_logging.arn

  tags = var.tags
}

resource "aws_transfer_user" "write_only" {
  for_each = var.users_write_only

  server_id      = aws_transfer_server.sftp.id
  user_name      = each.key
  role           = aws_iam_role.sftp_transfer.arn
  home_directory = "/${aws_s3_bucket.sftp_transfer[0].bucket}/${var.home_dir_prefix}${each.key}"
  policy         = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "s3:ListBucket"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::$${transfer:HomeBucket}"
          ],
          "Condition": {
              "StringLike": {
                  "s3:prefix": [
                      "$${transfer:HomeFolder}/*",
                      "$${transfer:HomeFolder}"
                  ]
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:PutObject"
          ],
          "Resource": "arn:aws:s3:::$${transfer:HomeDirectory}*"
       }
  ]
}
POLICY
}

resource "aws_transfer_user" "read_only" {
  for_each = var.users_read_only

  server_id      = aws_transfer_server.sftp.id
  user_name      = each.key
  role           = aws_iam_role.sftp_transfer.arn
  home_directory = "/${aws_s3_bucket.sftp_transfer[0].bucket}/${var.home_dir_prefix}${each.key}"
  policy         = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "s3:ListBucket"
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::$${transfer:HomeBucket}"
          ],
          "Condition": {
              "StringLike": {
                  "s3:prefix": [
                      "$${transfer:HomeFolder}/*",
                      "$${transfer:HomeFolder}"
                  ]
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:GetObject"
          ],
          "Resource": "arn:aws:s3:::$${transfer:HomeDirectory}*"
       }
  ]
}
POLICY
}

resource "aws_transfer_user" "read_write" {
  for_each = var.users_read_write

  server_id      = aws_transfer_server.sftp.id
  user_name      = each.key
  role           = aws_iam_role.sftp_transfer.arn
  home_directory = "/${aws_s3_bucket.sftp_transfer[0].bucket}/${var.home_dir_prefix}${each.key}"
  policy         = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "s3:ListBucket",
              "s3:GetObject",
          ],
          "Effect": "Allow",
          "Resource": [
              "arn:aws:s3:::$${transfer:HomeBucket}"
          ],
          "Condition": {
              "StringLike": {
                  "s3:prefix": [
                      "$${transfer:HomeFolder}/*",
                      "$${transfer:HomeFolder}"
                  ]
              }
          }
      },
      {
          "Effect": "Allow",
          "Action": [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
          ],
          "Resource": "arn:aws:s3:::$${transfer:HomeDirectory}*"
       }
  ]
}
POLICY
}

resource "aws_iam_role" "sftp_transfer" {
  name               = "sftp_transfer"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "transfer.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = merge(var.tags)
}

resource "aws_iam_role_policy" "sftp_transfer" {
  name = "sftp_transfer"
  role = aws_iam_role.sftp_transfer.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "${aws_s3_bucket.sftp_transfer[0].arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "${aws_s3_bucket.sftp_transfer[0].arn}/*"
        }
    ]
}
POLICY
}

resource "aws_transfer_ssh_key" "all" {
  for_each = merge(var.users_write_only, var.users_read_only, var.users_read_write)

  server_id  = aws_transfer_server.sftp.id
  user_name  = each.key
  body       = each.value
  depends_on = [
                   aws_transfer_user.write_only,
                   aws_transfer_user.read_only,
                   aws_transfer_user.read_write,
               ]
}

resource "aws_s3_bucket" "sftp_transfer" {
  count  = var.manage_bucket ? 1 : 0
  bucket = var.bucket_name

  logging {
    target_bucket = length(aws_s3_bucket.sftp_transfer_s3_logging) > 0 ? aws_s3_bucket.sftp_transfer_s3_logging[0].id : var.bucket_name_logging
    target_prefix = var.bucket_prefix_logging
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    expiration {
      days = var.s3_object_expiration_days
    }
  }

  tags = merge(var.tags)
}

resource "aws_s3_bucket_public_access_block" "sftp_transfer" {
  count                   = var.manage_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.sftp_transfer[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "sftp_transfer_s3_logging" {
  count  = var.manage_bucket_logging ? 1 : 0
  bucket = var.bucket_name_logging
  acl    = "log-delivery-write"

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(var.tags)
}

resource "aws_s3_bucket_public_access_block" "sftp_transfer_s3_logging" {
  count                   = var.manage_bucket ? 1 : 0
  bucket                  = length(aws_s3_bucket.sftp_transfer_s3_logging) > 0 ? aws_s3_bucket.sftp_transfer_s3_logging[count.index].id : ""
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_route53_record" "sftp" {
  count   = length(var.custom_dns_domain) > 0 ? 1 : 0
  zone_id = data.aws_route53_zone.custom_dns[count.index].id
  name    = "sftp"
  type    = "CNAME"
  ttl     = "5"

  records = [aws_transfer_server.sftp.endpoint]
}

data "aws_route53_zone" "custom_dns" {
  count = length(var.custom_dns_hostname) > 0 ? 1 : 0
  name  = var.custom_dns_domain
}

resource "aws_iam_role" "sftp_transfer_logging" {
  name = "tf-test-transfer-server-iam-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  tags = merge(var.tags)
}

resource "aws_iam_role_policy" "sftp_transfer_logging" {
  name = "sftp_transfer_logging"
  role = aws_iam_role.sftp_transfer_logging.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:CreateLogGroup",
            "logs:PutLogEvents"
        ],
        "Resource": "*"
        }
    ]
}
POLICY
}

data "aws_cloudwatch_log_group" "sftp" {
  name = "/aws/transfer/${aws_transfer_server.sftp.id}"
}
