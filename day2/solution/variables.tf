variable "region" {
  type        = string
  description = "실습 리전"
  default     = "ap-northeast-2"
}

# 서버 목록: 이름(키) => 서버 설정(object)
# 여기에 한 줄만 추가하면 서버와 보안 그룹이 함께 하나씩 늘어납니다.
variable "servers" {
  type = map(object({
    instance_type = string
    role          = string
    ports         = list(number)
  }))
  description = "만들 서버 목록 (이름 => 설정)"
  default = {
    web = {
      instance_type = "t3.micro"
      role          = "웹 서버"
      ports         = [80, 443]
    }
    app = {
      instance_type = "t3.micro"
      role          = "앱 서버"
      ports         = [80, 8080]
    }
  }
}
