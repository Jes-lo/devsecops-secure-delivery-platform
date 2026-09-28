provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "devsecops-secure-delivery-platform"
      ManagedBy = "Terraform"
      Purpose   = "SupplyChainEvidence"
    }
  }
}
