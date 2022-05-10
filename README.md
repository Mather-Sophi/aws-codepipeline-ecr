## aws-codepipeline-ecr
Creates a pipeline that builds a container via codebuild and pushes it to an ECR repo

## Usage

```hcl
module "ecr_pipeline" {
  source = "github.com/globeandmail/aws-codepipeline-ecr?ref=2.0"

  name               = app-name
  ecr_name           = repo-name
  github_repo_owner  = github-account-name
  github_repo_name   = github-repo-name
  github_oauth_token = data.aws_ssm_parameter.github_token.value
  tags = {
    Environment = var.environment
  }
  use_repo_access_github_token = true
  svcs_account_github_token_aws_secret_arn = svcs-account-github-token-aws-secret-arn
  svcs_account_github_token_aws_kms_cmk_arn = svcs-account-github-token-aws-kms-cmk-arn
  s3_block_public_access = true
}
```

## v1.3 Note
The account that owns the guthub token must have admin access on the repo in order to generate a github webhook 

## v1.4 Note
If `use_docker_credentials` is set to `true`, the environment variables `DOCKERHUB_USER` and `DOCKERHUB_PASS` are exposed via codebuild

You can add these 2 lines to the beginning of your `build` phase commands in `buildspec.yml` to login to Dockerhub

```yml
  build:
    commands:
      - echo "Logging into Dockerhub..."
      - docker login -u ${DOCKERHUB_USER} -p ${DOCKERHUB_PASS}
      ...
      ...
```

## v1.7 Note
The secrets manager environment variable `REPO_ACCESS_GITHUB_TOKEN_SECRETS_ID` is exposed via codebuild.

You can add the first line to the beginning of your `build` phase commands in `buildspec.yml` to assign the token's secret value to local variable `GITHUB_TOKEN`.

```yml
  build:
    commands:
      - export GITHUB_TOKEN=${REPO_ACCESS_GITHUB_TOKEN_SECRETS_ID}
      ...
      ...
      - docker build -t $REPOSITORY_URI:latest --build-arg GITHUB_TOKEN=${GITHUB_TOKEN} .
      ...
      ...
```

## v1.9 Note
If `use_repo_access_github_token` is set to `true`, the environment variable `REPO_ACCESS_GITHUB_TOKEN_SECRETS_ID` is exposed via codebuild.
Usage remains the same as v1.7.
If `s3_block_public_access` is set to `true`, the block public access setting for the artifact bucket is enabled.

## 2.0 Note
Uses aws-codebuild-project 2.0 for AWS provider 4
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| name | The name associated with the pipeline and assoicated resources. ie: app-name | string | n/a | yes |
| ecr\_name | The name of the ECR repo | string | n/a | yes |
| github\_repo\_owner | The owner of the GitHub repo | string | n/a | yes |
| github\_repo\_name | The name of the GitHub repository | string | n/a | yes |
| github\_oauth\_token | GitHub oauth token | string | n/a | yes |
| github\_branch\_name | The git branch name to use for the codebuild project | string | `"master"` | no |
| buildspec | The name of the buildspec file to use | string | buildspec.yml | no |
| codebuild\_image | The codebuild image to use | string | `"null"` | no |
| tags | A mapping of tags to assign to the resource | map | `{}` | no |
| use\_repo\_access\_github\_token | \(Optional\) Allow the AWS codebuild IAM role read access to the REPO\_ACCESS\_GITHUB\_TOKEN secrets manager secret in the shared service account.<br>Defaults to false. | `bool` | `false` | no |
| svcs\_account\_github\_token\_aws\_secret\_arn | \(Optional\) The AWS secret ARN for the repo access Github token.<br>The secret is created in the shared service account.<br>Required if var.use\_repo\_access\_github\_token is true. | `string` | `null` | no |
| svcs\_account\_github\_token\_aws\_kms\_cmk\_arn | \(Optional\)  The us-east-1 region AWS KMS customer managed key ARN for encrypting the repo access Github token AWS secret.<br>The key is created in the shared service account.<br>Required if var.use\_repo\_access\_github\_token is true. | `string` | `null` | no |
| create\_github\_webhook | Create the github webhook that triggers codepipeline | bool | `"true"` | no |
| s3\_block\_public\_access | \(Optional\) Enable the S3 block public access setting for the artifact bucket. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| artifact\_bucket\_arn |  |
| artifact\_bucket\_id |  |
| codebuild\_project\_arn |  |
| codebuild\_project\_id |  |
| codepipeline\_arn |  |
| codepipeline\_id |  |

## Builspec example
```yml
version: 0.2

env:
  variables:
    IMAGE_REPO_NAME: "ecr-repo-name"

phases:
  install:
    runtime-versions:
      docker: 18
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - $(aws ecr get-login --region $AWS_DEFAULT_REGION --no-include-email)
      - AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
      - REPOSITORY_URI=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $REPOSITORY_URI:latest .
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker images...
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
```
