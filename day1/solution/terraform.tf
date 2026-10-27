# Terraform과 AWS Provider 버전 고정
# - 수강생마다 다른 버전이 설치되어 결과가 달라지는 것을 막습니다.
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
