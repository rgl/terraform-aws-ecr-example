# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.6.6"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/aws
    # see https://github.com/hashicorp/terraform-provider-aws
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.1"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
    }
  }
}

variable "project" {
  type    = string
  default = "aws-ecr-example"
}

variable "environment" {
  type    = string
  default = "test"
}

# get the available locations with: aws ec2 describe-regions | jq -r '.Regions[].RegionName' | sort
variable "region" {
  type    = string
  default = "eu-west-1"
}

locals {
  repositories = [
    "example",
  ]
}

output "registry_region" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example
  #                     ^^^^^^^^^
  #                     region
  value = regex("^(?P<domain>[^/]+\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com)", module.ecr_repository["example"].repository_url)["region"]
}

output "registry_domain" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example
  #      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #      domain
  value = regex("^(?P<domain>[^/]+\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com)", module.ecr_repository["example"].repository_url)["domain"]
}

output "repositories" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example
  value = sort([for r in module.ecr_repository : r.repository_url])
}

# a private container image repository.
# see https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws
# see https://github.com/terraform-aws-modules/terraform-aws-ecr
module "ecr_repository" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  for_each = { for r in local.repositories : r => r }

  repository_name               = "${var.project}/${each.value}"
  repository_type               = "private"
  repository_force_delete       = true
  repository_image_scan_on_push = false
  create_lifecycle_policy       = false
}
