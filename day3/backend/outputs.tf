output "bucket" {
  description = "state 보관용 버킷 이름"
  value       = aws_s3_bucket.state.bucket
}
