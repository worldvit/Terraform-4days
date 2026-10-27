variable "region" {
  type        = string
  description = "실습 리전"
  default     = "ap-northeast-2"
}

variable "github_owner" {
  type        = string
  description = "GitHub 사용자 이름 (예: hong-gildong)"
}

variable "github_repo" {
  type        = string
  description = "GitHub 저장소 이름"
  default     = "tf4d-day4"
}

variable "create_oidc_provider" {
  type        = bool
  description = "GitHub OIDC 공급자를 새로 만들지 여부. 계정에 이미 있으면 false"
  default     = true
}
