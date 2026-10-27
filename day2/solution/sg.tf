# 서버마다 보안 그룹 1개 (for_each)
# 그 안의 인바운드 규칙은 서버별 ports 목록만큼 (dynamic)
resource "aws_security_group" "server" {
  for_each = var.servers

  name        = "tf4d-day2-${each.key}-sg"
  description = "tf4d day2 ${each.key} server"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = each.value.ports
    content {
      description = "port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf4d-day2-${each.key}-sg"
  }
}
