locals {
  name = "tf4d-day3"

  # 앞에서부터 az_count 개의 가용 영역 (예: ap-northeast-2a, ap-northeast-2b)
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # AZ 이름 => 서브넷 CIDR
  #   public : 10.0.0.0/24, 10.0.1.0/24
  #   private: 10.0.10.0/24, 10.0.11.0/24
  public_subnets  = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, i) }
  private_subnets = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, i + 10) }
}
