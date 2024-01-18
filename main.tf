# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.7.0"
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
  images = {
    example    = "docker.io/ruilopes/example-docker-buildx-go:v1.10.0"
    hello-etcd = "ghcr.io/rgl/hello-etcd:0.0.1"
  }
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

output "images" {
  # e.g. 123456.dkr.ecr.eu-west-1.amazonaws.com/aws-ecr-example/example:1.2.3
  value = {
    for key, value in local.images : key => "${module.ecr_repository[key].repository_url}:${regex(":(?P<tag>.+)$", value)["tag"]}"
  }
}

# a private container image repository.
# see https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws
# see https://github.com/terraform-aws-modules/terraform-aws-ecr
module "ecr_repository" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "1.6.0"

  for_each = local.images

  repository_name               = "${var.project}/${each.key}"
  repository_type               = "private"
  repository_force_delete       = true
  repository_image_scan_on_push = false
  create_lifecycle_policy       = false
}

# see https://developer.hashicorp.com/terraform/language/resources/terraform-data
resource "terraform_data" "ecr_image" {
  for_each = local.images

  triggers_replace = {
    source_image  = each.value
    target_image  = module.ecr_repository[each.key].repository_url
    target_region = var.region
  }

  provisioner "local-exec" {
    when = create
    environment = {
      ECR_IMAGE_COMMAND       = "copy"
      ECR_IMAGE_SOURCE_IMAGE  = each.value
      ECR_IMAGE_TARGET_IMAGE  = module.ecr_repository[each.key].repository_url
      ECR_IMAGE_TARGET_REGION = var.region
    }
    interpreter = ["bash"]
    command     = "${path.module}/ecr-image.sh"
  }

  provisioner "local-exec" {
    when = destroy
    environment = {
      ECR_IMAGE_COMMAND       = "delete"
      ECR_IMAGE_SOURCE_IMAGE  = self.triggers_replace.source_image
      ECR_IMAGE_TARGET_IMAGE  = self.triggers_replace.target_image
      ECR_IMAGE_TARGET_REGION = self.triggers_replace.target_region
    }
    interpreter = ["bash"]
    command     = "${path.module}/ecr-image.sh"
  }
}
