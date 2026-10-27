output "state_bucket" {
  description = "GitHub 저장소 변수 TF_STATE_BUCKET 에 넣을 값"
  value       = aws_s3_bucket.state.bucket
}

output "role_arn" {
  description = "GitHub 저장소 변수 AWS_ROLE_ARN 에 넣을 값"
  value       = aws_iam_role.github_actions.arn
}
