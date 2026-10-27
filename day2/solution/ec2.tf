# 서버 목록(var.servers)의 항목마다 EC2 1대 (for_each)
resource "aws_instance" "server" {
  for_each = var.servers

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = [aws_security_group.server[each.key].id]

  # 서버가 처음 켜질 때 실행할 스크립트 (서버마다 다른 페이지)
  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    name = each.key
    role = each.value.role
  })
  user_data_replace_on_change = true

  tags = {
    Name = "tf4d-day2-${each.key}"
    Role = each.key
  }
}
