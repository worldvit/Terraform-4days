# 단계 3: 변수와 tfvars로 EC2 만들기

# 최신 Amazon Linux 2023 이미지를 찾아오는 블록입니다.
# data 블록은 Day 2에서 자세히 배웁니다. 지금은 그대로 사용하세요.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.al2023.id
  instance_type = var.instance_type

  tags = {
    Name = "tf4d-day1-web"
  }
}
