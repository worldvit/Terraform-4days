# 단계 2: 변수로 이름을 받는 S3 버킷 + 버전 관리
resource "aws_s3_bucket" "lab" {
  bucket        = var.bucket_name
  force_destroy = true # 실습용: 안에 파일이 있어도 destroy 가능

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "lab" {
  bucket = aws_s3_bucket.lab.id

  versioning_configuration {
    status = "Enabled"
  }
}
