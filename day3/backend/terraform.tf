# Terraform과 AWS Provider 버전 고정
# - Day 3은 S3 backend의 use_lockfile(1.11부터 정식 기능)을 쓰므로 1.11 이상이 필요합니다.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
