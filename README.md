## aws-codepipeline-ecr
Creates a pipeline that builds a container via codebuild and pushes it to an ECR repo

## Usage

```hcl
module "ecr_pipeline" {
  source = "github.com/globeandmail/aws-codepipeline-ecr?ref=2.2"

  name               = app-name
  ecr_name           = repo-name
  github_repo_owner  = github-account-name
  github_repo_name   = github-repo-name
  github_oauth_token = data.aws_ssm_parameter.github_token.value
  tags = {
    Environment = var.environment
  }
  use_repo_access_github_token = true
  svcs_account_github_token_aws_secret_arn     = svcs-account-github-token-aws-secret-arn
  svcs_account_aws_kms_cmk_arn                 = svcs-account-aws-kms-cmk-arn
  s3_block_public_access                       = true
  use_sysdig_api_token                         = true
  svcs_account_sysdig_api_token_aws_secret_arn = svcs-account-sysdig-api-token-aws-secret-arn
}
```

## v1.3 Note
The account that owns the guthub token must have admin access on the repo in order to generate a github webhook 

## v1.4 Note
If `use_docker_credentials` is set to `true`, the environment variables `DOCKERHUB_USER` and `DOCKERHUB_PASS` are exposed via codebuild.

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

## v.2.1 Note
If `use_sysdig_api_token` is set to `true`, the secrets manager environment variable `SYSDIG_API_TOKEN_SECRETS_ID` is exposed via codebuild.

You can add these 8 lines to the end of your `build` phase commands in `buildspec.yml` to run Sysdig image security scans.
```yml
  build:
    commands:
      ...
      ...
      - echo "Running Sysdig image inline scan..."
      - docker run --rm -u $(id -u) -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/reports:/staging/reports quay.io/sysdig/secure-inline-scan:2 -s https://us2.app.sysdig.com -k ${SYSDIG_API_TOKEN_SECRETS_ID} --storage-type docker-daemon --storage-path /var/run/docker.sock -r /staging/reports ${REPOSITORY_URI}:${IMAGE_TAG} || true
      - echo "Downloading Sysdig Cli Scanner..."
      - curl -LO "https://download.sysdig.com/scanning/bin/sysdig-cli-scanner/$(curl -L -s https://download.sysdig.com/scanning/sysdig-cli-scanner/latest_version.txt)/linux/amd64/sysdig-cli-scanner"
      - echo "Adding executable permission to sysdig-cli-scanner binary..."
      - chmod +x ./sysdig-cli-scanner
      - echo "Running Sysdig image cli scan..."
      - SECURE_API_TOKEN=${SYSDIG_API_TOKEN_SECRETS_ID} ./sysdig-cli-scanner --apiurl https://us2.app.sysdig.com ${REPOSITORY_URI}:${IMAGE_TAG} --policy sysdig_best_practices || true
```
## v.2.2 Note
The `aws-codebuild-project` version is upgraded to version `2.2` to override AWS S3 bucket default ACL setting. The AWS S3 security changes can be found in the AWS blog [here](https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/).

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
| build\_compute\_type | Build environment compute type | string | `"null"` | no |
| tags | A mapping of tags to assign to the resource | map | `{}` | no |
| use\_repo\_access\_github\_token | \(Optional\) Allow the AWS codebuild IAM role read access to the REPO\_ACCESS\_GITHUB\_TOKEN secrets manager secret in the shared service account.<br>Defaults to false. | `bool` | `false` | no |
| svcs\_account\_github\_token\_aws\_secret\_arn | \(Optional\) The AWS secret ARN for the repo access Github token.<br>The secret is created in the shared service account.<br>Required if var.use\_repo\_access\_github\_token is true. | `string` | `null` | no |
| svcs\_account\_aws\_kms\_cmk\_arn | \(Optional\)  The us-east-1 region AWS KMS customer managed key ARN for encrypting all AWS secrets.<br>The key is created in the shared service account.<br>Required if var.use\_repo\_access\_github\_token or var.use\_sysdig\_api\_token is true. | `string` | `null` | no | yes |
| create\_github\_webhook | Create the github webhook that triggers codepipeline | bool | `"true"` | no |
| s3\_block\_public\_access | \(Optional\) Enable the S3 block public access setting for the artifact bucket. | `bool` | `false` | no |
| use\_sysdig\_api\_token | \(Optional\) Allow the AWS codebuild IAM role read access to the SYSDIG\_API\_TOKEN secrets manager secret in the shared service account.<br>Defaults to false. | `bool` | `false` | no |
| svcs\_account\_sysdig\_api\_token\_aws\_secret\_arn | \(Optional\) The AWS secret ARN for the sysdig API token.<br>The secret is created in the shared service account.<br>Required if var.use\_sysdig\_api\_token is true. | `string` | `null` | no |

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
