# ---------------------------------------------------------------
# VPC와 인터넷 게이트웨이
# ---------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = { Name = "${local.name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${local.name}-igw" }
}

# ---------------------------------------------------------------
# 서브넷: AZ마다 public 1개, private 1개 (for_each)
# ---------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = true # 이 서브넷의 EC2는 퍼블릭 IP를 자동으로 받음

  tags = { Name = "${local.name}-public-${each.key}", Tier = "public" }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value

  tags = { Name = "${local.name}-private-${each.key}", Tier = "private" }
}

# ---------------------------------------------------------------
# NAT Gateway 1개 (첫 번째 public 서브넷에)
#   - 시간당 과금! 실습이 끝나면 반드시 destroy
# ---------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${local.name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[local.azs[0]].id

  tags = { Name = "${local.name}-nat" }

  # IGW가 먼저 있어야 NAT가 인터넷으로 나갈 수 있음
  depends_on = [aws_internet_gateway.main]
}

# ---------------------------------------------------------------
# 라우팅 테이블
#   public : 0.0.0.0/0 → 인터넷 게이트웨이
#   private: 0.0.0.0/0 → NAT Gateway
# ---------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "${local.name}-private-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
