variable "name" {
  type        = string
  description = "리소스 이름 앞에 붙일 접두사"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC 주소 범위"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "public 서브넷을 만들 가용 영역 수 (ALB는 2개 이상 필요)"
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "ALB를 쓰려면 az_count 는 2 이상이어야 합니다."
  }
}
