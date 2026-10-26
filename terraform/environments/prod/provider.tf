provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project = "tdb-devops-handson"
      Environment = var.environment
      ManagedBy = "Terraform"
    }
  }
}
