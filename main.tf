# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.6.6"
  required_providers {
    # see https://registry.terraform.io/providers/hashicorp/aws
    # see https://github.com/hashicorp/terraform-provider-aws
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
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

variable "example_repository_name" {
  type    = string
  default = "aws-ecr-example/example"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-._/]{1,255}$", var.example_repository_name))
    error_message = "The variable must start with a letter and have a length between 2 and 256 characters. It can only contain lowercase letters, numbers, hyphens, underscores, periods, and forward slashes."
  }
}

output "registry_region" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example
  #                     ^^^^^^^^^
  #                     region
  value = regex("^(?P<domain>[^/]+\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com)", module.ecr.repository_url)["region"]
}

output "registry_domain" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example
  #      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #      domain
  value = regex("^(?P<domain>[^/]+\\.ecr\\.(?P<region>[a-z0-9-]+)\\.amazonaws\\.com)", module.ecr.repository_url)["domain"]
}

output "example_repository_url" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example
  value = module.ecr.repository_url
}

# a private container image repository.
# see https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws
# see https://github.com/terraform-aws-modules/terraform-aws-ecr
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  repository_type = "private"
  repository_name = var.example_repository_name

  repository_force_delete = true

  repository_image_scan_on_push = false

  create_lifecycle_policy = false
}
