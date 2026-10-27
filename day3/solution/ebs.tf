# 웹 서버에 붙일 추가 디스크 10GB
# ※ 단계 3에서 terraform state mv 로 이름을 web_data 로 바꿉니다.
resource "aws_ebs_volume" "web_data" {
  availability_zone = aws_instance.web.availability_zone # 같은 AZ에만 붙일 수 있음
  size              = 10
  type              = "gp3"

  tags = { Name = "${local.name}-web-data" }
}

resource "aws_volume_attachment" "web_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.web_data.id
  instance_id = aws_instance.web.id
}
