# 웹 서버: HTTP는 누구나, SSH는 관리자(작업용 EC2)만
resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "tf4d day3 web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-web-sg" }
}

# 내부 서버: 웹 서버 보안 그룹에서 오는 SSH만 허용 (보안 그룹 참조)
resource "aws_security_group" "private" {
  name        = "${local.name}-private-sg"
  description = "tf4d day3 private server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-private-sg" }
}
