# S3-only remote backend (NO DynamoDB locking).
# Suitable for single-user or simple CI where runs won't overlap.
terraform {
  backend "s3" {
    bucket  = "tf-state-<YOUR-ACCOUNT-ID>-ap-south-1"  # e.g. tf-state-123456789012-ap-south-1
    key     = "landing-zone/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}
