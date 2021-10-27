variable "name" {
  type        = string
  description = "The name associated with the pipeline and assoicated resources. ie: app-name"
}

variable "ecr_name" {
  type        = string
  description = "The name of the ECR repo"
}

variable "github_repo_owner" {
  type        = string
  description = "The owner of the GitHub repo"
}

variable "github_repo_name" {
  type        = string
  description = "The name of the GitHub repository"
}

variable "github_branch_name" {
  type        = string
  description = "The git branch name to use for the codebuild project"
  default     = "master"
}

variable "github_oauth_token" {
  type        = string
  description = "GitHub oauth token"
}

variable "buildspec" {
  type        = string
  description = "The name of the buildspec file to use with codebuild"
  default     = "buildspec.yml"
}

variable "codebuild_image" {
  type        = string
  description = "The codebuild image to use"
  default     = null
}

variable "use_docker_credentials" {
  type        = bool
  description = "(Optional) Use dockerhub credentals stored in parameter store"
  default     = false
}

variable "tags" {
  type        = map
  description = "A mapping of tags to assign to the resource"
  default     = {}
}

variable "central_account_github_token_aws_secret_arn" {
  type = string
  description = "(Required) The repo access Github token AWS secret ARN in the central AWS account"
}

variable "central_account_github_token_aws_kms_cmk_arn" {
  type = string
  description = "(Required) The repo access Github token AWS KMS customer managed key ARN in the central AWS account"
}

variable "create_github_webhook" {
  type        = bool
  description = "Create the github webhook that triggers codepipeline. Defaults to true"
  default     = true
}

