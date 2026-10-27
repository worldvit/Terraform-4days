# bootstrap: CI/CD 가 쓰기 전에 사람이 한 번 만드는 기반 (state 버킷 + GitHub OIDC Role)
# 이 프로젝트의 state 는 로컬(작업용 EC2)에 둡니다.
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
