output "codepipeline_id" {
  value = aws_codepipeline.pipeline.id
}

output "codepipeline_arn" {
  value = aws_codepipeline.pipeline.arn
}

output "codebuild_project_id" {
  value = module.codebuild_project.codebuild_project_id
}

output "codebuild_project_arn" {
  value = module.codebuild_project.codebuild_project_arn
}

output "artifact_bucket_id" {
  value = module.codebuild_project.artifact_bucket_id
}

output "artifact_bucket_arn" {
  value = module.codebuild_project.artifact_bucket_arn
}
