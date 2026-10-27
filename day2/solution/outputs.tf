output "account_id" {
  description = "data로 조회한 AWS 계정 ID"
  value       = data.aws_caller_identity.current.account_id
}

output "ami_name" {
  description = "data로 찾은 Ubuntu AMI 이름"
  value       = data.aws_ami.ubuntu.name
}

output "availability_zones" {
  description = "data로 조회한 가용 영역 목록"
  value       = data.aws_availability_zones.available.names
}

output "server_ips" {
  description = "서버 이름 => 퍼블릭 IP"
  value       = { for name, server in aws_instance.server : name => server.public_ip }
}

output "server_urls" {
  description = "서버 이름 => 접속 주소"
  value       = { for name, server in aws_instance.server : name => "http://${server.public_ip}" }
}
