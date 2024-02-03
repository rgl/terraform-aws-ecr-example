# About

[![Lint](https://github.com/rgl/terraform-aws-ecr-example/actions/workflows/lint.yml/badge.svg)](https://github.com/rgl/terraform-aws-ecr-example/actions/workflows/lint.yml)

This creates private container image repositories hosted in the [AWS Elastic Container Registry (ECR)](https://aws.amazon.com/ecr/) of your AWS Account using a terraform program.

For equivalent examples see:

* [pulumi (aws classic provider)](https://github.com/rgl/pulumi-typescript-aws-classic-ecr-example)
* [pulumi (aws native provider)](https://github.com/rgl/pulumi-typescript-aws-native-ecr-example)

# Usage (on a Ubuntu Desktop)

Install the dependencies:

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
* [Terraform](https://www.terraform.io/downloads.html).
* [Crane](https://github.com/google/go-containerregistry/releases).
* [Docker](https://docs.docker.com/engine/install/).

Set the AWS Account credentials using SSO:

```bash
# set the environment variables to use a specific profile.
# e.g. use the pattern <aws-sso-session-name>-<aws-account-name>-<aws-account-role>-<aws-account-id>
export AWS_PROFILE=example-dev-AdministratorAccess-123456
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_DEFAULT_REGION
# set the account credentials.
# see https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html#sso-configure-profile-token-auto-sso
aws configure sso
# dump the configured profile and sso-session.
cat ~/.aws/config
# show the user, user amazon resource name (arn), and the account id, of the
# profile set in the AWS_PROFILE environment variable.
aws sts get-caller-identity
```

Or, set the AWS Account credentials using an Access Key:

```bash
# set the account credentials.
# NB get these from your aws account iam console.
#    see Managing access keys (console) at
#        https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey
export AWS_ACCESS_KEY_ID='TODO'
export AWS_SECRET_ACCESS_KEY='TODO'
unset AWS_PROFILE
# set the default region.
export AWS_DEFAULT_REGION='eu-west-1'
# show the user, user amazon resource name (arn), and the account id.
aws sts get-caller-identity
```

Review `main.tf`.

Initialize terraform:

```bash
make terraform-init
```

Launch the example:

```bash
make terraform-apply
```

Show the terraform state:

```bash
make terraform-state-list
make terraform-show
```

Log in the container registry:

**NB** You are logging in at the registry level. You are not logging in at the
repository level.

```bash
aws ecr get-login-password \
  --region "$(terraform output -raw registry_region)" \
  | docker login \
      --username AWS \
      --password-stdin \
      "$(terraform output -raw registry_domain)"
```

**NB** This saves the credentials in the `~/.docker/config.json` local file.

Inspect the created example container image:

```bash
image="$(terraform output -json images | jq -r .example)"
crane manifest "$image" | jq .
```

Download the created example container image from the created container image
repository, and execute it locally:

```bash
docker run --rm "$image"
```

Delete the local copy of the created container image:

```bash
docker rmi "$image"
```

Log out the container registry:

```bash
docker logout \
  "$(terraform output -raw registry_domain)"
```

Delete the example image resource:

```bash
terraform destroy -target='terraform_data.ecr_image["example"]'
```

At the ECR AWS Management Console, verify that the example image no longer
exists (actually, it's the image index/tag that no longer exists).

Do an `terraform apply` to verify that it recreates the example image:

```bash
make terraform-apply
```

Destroy the example:

```bash
make terraform-destroy
```

# Notes

* Its not possible to create multiple container image registries.
  * A single registry is automatically created when the AWS Account is created.
  * You have to create a separate repository for each of your container images.
    * A repository name can include several path segments (e.g. `hello/world`).

# References

* [Environment variables to configure the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
* [Token provider configuration with automatic authentication refresh for AWS IAM Identity Center](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html) (SSO)
* [Managing access keys (console)](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey)
* [AWS General Reference](https://docs.aws.amazon.com/general/latest/gr/Welcome.html)
  * [Amazon Resource Names (ARNs)](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html)
* [Amazon ECR private registry](https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html)
  * [Private registry authentication](https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html)
