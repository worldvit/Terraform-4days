provider "aws" {
  region = var.region

  # 이 코드로 만드는 모든 리소스에 자동으로 붙는 이름표
  # 채점(grade)과 정리 확인(cleanup)이 이 태그로 리소스를 찾습니다.
  default_tags {
    tags = {
      Course = "tf4d"
      Day    = "day1"
    }
  }
}
