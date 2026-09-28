resource "aws_s3_bucket" "supply_chain_evidence" {
  #checkov:skip=CKV_AWS_145:SSE-S3 provides encryption at rest without KMS key management or additional KMS cost for this non-production evidence bucket.
  #checkov:skip=CKV_AWS_144:Cross-region replication is intentionally omitted for this minimal non-production portfolio environment to avoid a second bucket, duplicated storage, and cross-region costs.
  #checkov:skip=CKV_AWS_18:Dedicated server access logging is intentionally omitted for this minimal non-production evidence bucket to avoid additional logging infrastructure and storage.
  #checkov:skip=CKV2_AWS_62:Event notifications are not configured because this bucket has no event-driven SNS, SQS, Lambda, or EventBridge consumer.

  bucket_prefix = var.bucket_prefix

  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "supply_chain_evidence" {
  bucket = aws_s3_bucket.supply_chain_evidence.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "supply_chain_evidence" {
  bucket = aws_s3_bucket.supply_chain_evidence.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "supply_chain_evidence" {
  bucket = aws_s3_bucket.supply_chain_evidence.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "supply_chain_evidence" {
  bucket = aws_s3_bucket.supply_chain_evidence.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "supply_chain_evidence" {
  bucket = aws_s3_bucket.supply_chain_evidence.id

  rule {
    id     = "cost-control"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.supply_chain_evidence
  ]
}
