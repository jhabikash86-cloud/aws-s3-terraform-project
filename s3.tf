# 1. Generate a Unique String for the Bucket Name
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Create the S3 Bucket
resource "aws_s3_bucket" "assets" {
  bucket        = "webapp-assets-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "webapp-assets-bucket"
  }
}

# 3. Block All Direct Public Access to the Bucket
resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
