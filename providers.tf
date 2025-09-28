terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "local" {}  # Jenkins runs locally; keep simple
}

variable "primary_region"   {}
variable "secondary_region" {}

provider "aws" { region = var.primary_region }
provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

# Discover AZs dynamically (no hardcoding a/b letters)
data "aws_availability_zones" "a" {}
data "aws_availability_zones" "b" { provider = aws.dr }
