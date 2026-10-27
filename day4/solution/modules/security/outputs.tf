output "alb_sg_id" {
  description = "ALB 보안 그룹 ID"
  value       = aws_security_group.alb.id
}

output "web_sg_id" {
  description = "웹 서버 보안 그룹 ID"
  value       = aws_security_group.web.id
}
