# public 서브넷의 웹 서버 (인터넷 게이트웨이로 직접 통신)
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[local.azs[0]].id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = templatefile("${path.module}/templates/web.sh.tftpl", {
    tier = "public"
  })
  user_data_replace_on_change = true

  tags = { Name = "${local.name}-web", Role = "web" }
}

# private 서브넷의 내부 서버 (퍼블릭 IP 없음, NAT로만 밖에 나감)
resource "aws_instance" "private" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[local.azs[0]].id
  vpc_security_group_ids = [aws_security_group.private.id]

  # 부팅하면 인터넷에 나가 보고, 밖에서 보인 내 IP를 콘솔 로그에 남김
  user_data                   = file("${path.module}/templates/nat_check.sh")
  user_data_replace_on_change = true

  tags = { Name = "${local.name}-private", Role = "private" }

  # NAT 경로가 다 만들어진 뒤에 서버를 켜야 첫 부팅에서 인터넷이 됨
  depends_on = [aws_route_table_association.private]
}
