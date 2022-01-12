data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

provider "github" {
  token = var.github_oauth_token
  owner = var.github_repo_owner
}

locals {
  aws_region = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "codepipeline-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "codepipeline_baseline" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${module.codebuild_project.artifact_bucket_arn}/*"
    ]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [module.codebuild_project.codebuild_project_arn]
  }

}

resource "aws_iam_role_policy" "codepipeline_baseline" {
  name   = "codepipeline-baseline-${var.name}"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_baseline.json
}

module "codebuild_project" {
  source = "github.com/globeandmail/aws-codebuild-project?ref=1.8"

  name                                         = var.name
  deploy_type                                  = "ecr"
  ecr_name                                     = var.ecr_name
  buildspec                                    = var.buildspec
  use_docker_credentials                       = var.use_docker_credentials
  tags                                         = var.tags
  use_repo_access_github_token                 = var.use_repo_access_github_token
  svcs_account_github_token_aws_secret_arn     = var.svcs_account_github_token_aws_secret_arn
  svcs_account_github_token_aws_kms_cmk_arn    = var.svcs_account_github_token_aws_kms_cmk_arn
  s3_block_public_access                       = var.s3_block_public_access
}

resource "aws_codepipeline" "pipeline" {
  name     = var.name
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = module.codebuild_project.artifact_bucket_id
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        Owner                = var.github_repo_owner
        Repo                 = var.github_repo_name
        Branch               = var.github_branch_name
        OAuthToken           = var.github_oauth_token
        PollForSourceChanges = "false"

      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["code"]
      # output_artifacts = ["none"]
      version = "1"

      configuration = {
        ProjectName = module.codebuild_project.codebuild_project_id
      }
    }
  }

  tags = var.tags
}

resource "aws_codepipeline_webhook" "github" {
  # Only create the webhook if create_github_webhook is set to true
  count           = var.create_github_webhook == true ? 1 : 0
  name            = var.name
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.pipeline.name

  authentication_configuration {
    secret_token = var.github_oauth_token
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

resource "github_repository_webhook" "aws_codepipeline" {
  repository = var.github_repo_name
  count      = var.create_github_webhook == true ? 1 : 0

  configuration {
    url          = aws_codepipeline_webhook.github[0].url
    content_type = "json"
    secret       = var.github_oauth_token
  }

  events = ["push"]
}
