variable "name" {
  type        = string
  description = "리소스 이름 앞에 붙일 접두사"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "ALB와 서버를 둘 서브넷 (서로 다른 AZ 2개 이상)"
}

variable "alb_sg_id" {
  type        = string
  description = "ALB 보안 그룹 ID"
}

variable "web_sg_id" {
  type        = string
  description = "웹 서버 보안 그룹 ID"
}

variable "instance_type" {
  type        = string
  description = "웹 서버 인스턴스 유형"
  default     = "t3.micro"
}

variable "app_version" {
  type        = string
  description = "웹 페이지에 표시할 버전"
  default     = "v1"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}
