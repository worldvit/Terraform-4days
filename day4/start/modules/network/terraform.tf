# 모듈은 provider 를 설정하지 않고, 필요한 provider 와 버전만 밝힙니다.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
