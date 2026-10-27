# data 블록: 이미 있는 정보를 조회만 합니다. (만들거나 바꾸지 않음)

# 최신 Ubuntu 24.04 LTS 이미지 (Canonical 공식 계정)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# 지금 리전에서 쓸 수 있는 가용 영역 목록
data "aws_availability_zones" "available" {
  state = "available"
}

# 지금 Terraform을 실행하는 계정 정보
data "aws_caller_identity" "current" {}

# 기본 VPC (작업용 EC2가 있는 곳)
data "aws_vpc" "default" {
  default = true
}
