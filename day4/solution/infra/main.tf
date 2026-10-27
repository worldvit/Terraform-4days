locals {
  name = "tf4d-day4"
}

# ① 네트워크: VPC + public 서브넷 2개
module "network" {
  source = "../modules/network"

  name     = local.name
  vpc_cidr = "10.40.0.0/16"
  az_count = 2
}

# ② 보안 그룹: ALB(80 공개) → 웹 서버(80, ALB에서만)
module "security" {
  source = "../modules/security"

  name   = local.name
  vpc_id = module.network.vpc_id
}

# ③ 웹 서비스: ALB + Launch Template + Auto Scaling Group
module "web" {
  source = "../modules/web"

  name          = local.name
  vpc_id        = module.network.vpc_id
  subnet_ids    = module.network.public_subnet_ids
  alb_sg_id     = module.security.alb_sg_id
  web_sg_id     = module.security.web_sg_id
  instance_type = "t3.micro"
  app_version   = var.app_version

  min_size         = 2
  max_size         = 4
  desired_capacity = 2
}
