output "user_arn" {
  description = "IAM 사용자 ARN"
  value       = aws_iam_user.adam.arn
}

output "bucket_arn" {
  description = "S3 버킷 ARN"
  value       = aws_s3_bucket.lab.arn
}

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "EC2 퍼블릭 IP"
  value       = aws_instance.web.public_ip
}
