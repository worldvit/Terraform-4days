output "alb_dns_name" {
  description = "ALB 주소"
  value       = aws_lb.this.dns_name
}

output "asg_name" {
  description = "Auto Scaling Group 이름"
  value       = aws_autoscaling_group.this.name
}

output "target_group_arn" {
  value = aws_lb_target_group.this.arn
}
