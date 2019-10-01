data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  aws_region = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
  datetime   = formatdate("YYYYMMDDhhmmss", timestamp())
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
  name               = "codepipeline-${var.name}-${local.datetime}"
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
}

resource "aws_iam_role_policy" "codepipeline_baseline" {
  name   = "codepipeline-baseline-${var.name}"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_baseline.json
}

module "codebuild_project" {
  source = "../aws-codebuild-project"

  name        = var.name
  deploy_type = ecr
  ecr_name    = var.ecr_name
  tags        = var.tags
}

resource "aws_codepipeline" "pipeline" {
  name     = var.name
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = module.codebuild_project.artifact_bucket_arn
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
        Owner      = var.github_repo_owner
        Repo       = var.github_repo_name
        Branch     = var.github_branch_name
        OAuthToken = var.github_oauth_token
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
