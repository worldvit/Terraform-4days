output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "AZ => public 서브넷 ID"
  value       = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnet_ids" {
  description = "AZ => private 서브넷 ID"
  value       = { for az, s in aws_subnet.private : az => s.id }
}

output "nat_public_ip" {
  description = "NAT Gateway의 공인 IP (private 서버가 밖에 나갈 때 쓰는 IP)"
  value       = aws_eip.nat.public_ip
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}

output "web_instance_id" {
  value = aws_instance.web.id
}

output "private_instance_id" {
  value = aws_instance.private.id
}

output "private_ip" {
  value = aws_instance.private.private_ip
}

output "ssh_web" {
  description = "작업용 EC2에서 웹 서버로 접속하는 명령 (키 파일 없이 EC2 Instance Connect)"
  value       = "aws ec2-instance-connect ssh --instance-id ${aws_instance.web.id} --os-user ec2-user"
}
