variable "region" {
  type        = string
  description = "실습 리전"
  default     = "ap-northeast-2"
}

variable "app_version" {
  type        = string
  description = "웹 페이지에 표시할 버전. 바꾸면 ASG가 서버를 차례로 교체합니다 (단계 4에서 v2로)"
  default     = "v1"
}
