output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "public 서브넷 ID 목록 (AZ 순서)"
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "azs" {
  description = "사용한 가용 영역"
  value       = local.azs
}
