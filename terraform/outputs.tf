output "supply_chain_evidence_bucket_name" {
  description = "Name of the private S3 bucket used for supply-chain evidence."
  value       = aws_s3_bucket.supply_chain_evidence.id
}

output "supply_chain_evidence_bucket_arn" {
  description = "ARN of the private S3 bucket used for supply-chain evidence."
  value       = aws_s3_bucket.supply_chain_evidence.arn
}
