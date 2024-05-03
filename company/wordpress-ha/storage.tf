resource "aws_s3_bucket" "wp_static" {
  bucket = "cdn.${var.host}"

  tags = {
    Name        = "${var.name}-${var.environment}-bucket"
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket_ownership_controls" "wp_static_ownership" {
  bucket = aws_s3_bucket.wp_static.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "wp_static_acl" {
  bucket = aws_s3_bucket.wp_static.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "wp_public_access_block" {
  bucket = aws_s3_bucket.wp_static.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
