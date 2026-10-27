output "alb_url" {
  description = "웹 서비스 주소 (ALB)"
  value       = "http://${module.web.alb_dns_name}"
}

output "asg_name" {
  value = module.web.asg_name
}

output "vpc_id" {
  value = module.network.vpc_id
}
