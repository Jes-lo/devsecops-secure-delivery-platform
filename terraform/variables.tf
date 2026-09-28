variable "aws_region" {
  description = "AWS region used for the supply-chain evidence bucket."
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  description = "Prefix used for the globally unique S3 bucket name."
  type        = string
  default     = "devsecops-supply-chain-evidence-"

  validation {
    condition = (
      length(var.bucket_prefix) >= 3 &&
      length(var.bucket_prefix) <= 37
    )

    error_message = "bucket_prefix must be between 3 and 37 characters."
  }
}
