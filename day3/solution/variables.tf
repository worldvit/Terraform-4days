variable "region" {
  type        = string
  description = "실습 리전"
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC 전체 주소 범위"
  default     = "10.0.0.0/16"
}

variable "az_count" {
  type        = number
  description = "사용할 가용 영역 수 (public · private 서브넷을 AZ마다 1개씩)"
  default     = 2
}

variable "instance_type" {
  type        = string
  description = "EC2 인스턴스 유형"
  default     = "t3.micro"
}

variable "admin_cidr" {
  type        = string
  description = "웹 서버에 SSH(22)로 들어올 수 있는 주소. 작업용 EC2의 퍼블릭 IP/32"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr 는 1.2.3.4/32 처럼 CIDR 형식이어야 합니다."
  }
}
