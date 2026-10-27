# state 보관용 S3 버킷 (Day 3 단계 3)
# - 버킷 이름에 계정 ID를 넣어 전 세계에서 겹치지 않게 합니다.
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  bucket        = "tf4d-day3-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # 실습용: 안에 state가 남아 있어도 destroy 가능

  tags = { Name = "tf4d-day3-state" }
}

# 버전 관리: state를 잘못 덮어써도 이전 버전으로 되돌릴 수 있음
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 퍼블릭 접근 완전 차단: state에는 민감 정보가 들어갈 수 있음
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
