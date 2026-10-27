variable "region" {
  description = "실습 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "bucket_name" {
  description = "S3 버킷 이름 (전 세계에서 유일해야 함, 소문자·숫자·하이픈만)"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 유형"
  type        = string
  default     = "t3.micro"
}
