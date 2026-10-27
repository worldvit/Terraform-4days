variable "name" {
  type        = string
  description = "리소스 이름 앞에 붙일 접두사"
}

variable "vpc_id" {
  type        = string
  description = "보안 그룹을 만들 VPC"
}
