# S3-only remote backend (NO DynamoDB locking).
# Suitable for single-user or simple CI where runs won't overlap.

terraform {
  backend "s3" {
    bucket  = "tf-state-043976678532-ap-south-1" # 👈 your bucket name
    key     = "landing-zone/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}