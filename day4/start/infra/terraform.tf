# Root module: 모듈들을 조립해서 실제 인프라를 만드는 곳
# - S3 backend 의 use_lockfile 을 쓰므로 1.11 이상
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
