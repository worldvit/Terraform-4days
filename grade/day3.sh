#!/bin/bash
# Day 3 채점 (따라하기 버전 전용)
# 사용법: 실습 폴더에서   bash ~/Terraform-4days/grade/day3.sh
#         다른 위치에서   bash ~/Terraform-4days/grade/day3.sh ~/day3
# ※ terraform destroy 하기 "전에", 단계 3(S3 backend 이전)까지 마친 뒤 실행하세요.

DIR="${1:-$PWD}"
STEPS=12
source "$(dirname "$0")/lib/common.sh"
require_tools
cd "$DIR" || { echo "폴더가 없습니다: $DIR"; exit 1; }

title "Day 3 채점 — 2계층 네트워크 위의 서버"
echo " 실습 폴더: $DIR"
echo

# ---- 미리 값 모으기 (조회만) ----
STATE=$(terraform state list 2>/dev/null)
VPC_ID=$(tf_out vpc_id)
NAT_IP=$(tf_out nat_public_ip)
WEB_URL=$(tf_out web_url)
WEB_ID=$(tf_out web_instance_id)
PRIV_ID=$(tf_out private_instance_id)
BACKEND_TYPE=$(jq -r '.backend.type // empty' .terraform/terraform.tfstate 2>/dev/null)
BACKEND_BUCKET=$(jq -r '.backend.config.bucket // empty' .terraform/terraform.tfstate 2>/dev/null)
BACKEND_KEY=$(jq -r '.backend.config.key // empty' .terraform/terraform.tfstate 2>/dev/null)
export STATE VPC_ID NAT_IP WEB_URL WEB_ID PRIV_ID BACKEND_TYPE BACKEND_BUCKET BACKEND_KEY

# ---- 공통 ----
check "terraform init 완료" \
  "실습 폴더에서 terraform init 을 실행했는지 확인하세요" \
  test -d .terraform

# ---- 단계 1: VPC · 서브넷 · NAT · EC2 ----
check "VPC 10.0.0.0/16 (Day=day3)" \
  "output \"vpc_id\" 가 있는지, VPC cidr_block 이 10.0.0.0/16 인지 확인하세요" \
  bash -c '[ -n "$VPC_ID" ] && [ "$(aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --filters Name=tag:Day,Values=day3 --query "Vpcs[0].CidrBlock" --output text)" = "10.0.0.0/16" ]'

check "public 서브넷 2개 · private 서브넷 2개" \
  "aws_subnet public/private 에 for_each 를 썼는지, public 에 map_public_ip_on_launch = true 인지 확인하세요" \
  bash -c 'p=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query "length(Subnets[?MapPublicIpOnLaunch==\`true\`])" --output text);
           q=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query "length(Subnets[?MapPublicIpOnLaunch==\`false\`])" --output text);
           [ "$p" -ge 2 ] && [ "$q" -ge 2 ]'

check "NAT Gateway 정확히 1개" \
  "aws_nat_gateway 가 1개인지, 상태가 available 인지 확인하세요 (만들어지는 데 2~3분)" \
  bash -c '[ "$(aws ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC_ID" Name=state,Values=available --query "length(NatGateways)" --output text)" = "1" ]'

check "private 라우팅: 0.0.0.0/0 → NAT" \
  "private 라우팅 테이블의 route 에 nat_gateway_id 를 넣고 private 서브넷과 연결했는지 확인하세요" \
  bash -c '[ "$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" --query "length(RouteTables[].Routes[?DestinationCidrBlock==\`0.0.0.0/0\` && NatGatewayId][])" --output text)" -ge 1 ]'

check "웹 서버 페이지 접속 (public)" \
  "output \"web_url\" 을 확인하고, 막 만들었다면 2~3분 뒤 다시 실행하세요" \
  bash -c '[ -n "$WEB_URL" ] && curl -s -m 5 "$WEB_URL" | grep -q "public web"'

check "내부 서버에 퍼블릭 IP 없음" \
  "aws_instance.private 를 private 서브넷에 두었는지 확인하세요 (output \"private_instance_id\")" \
  bash -c '[ -n "$PRIV_ID" ] && [ "$(aws ec2 describe-instances --instance-ids "$PRIV_ID" --query "Reservations[0].Instances[0].PublicIpAddress" --output text)" = "None" ]'

check "내부 서버가 NAT IP로 인터넷 접속" \
  "콘솔 로그에 TF4D-NAT-CHECK 줄이 나오기까지 3~5분 걸립니다. 잠시 뒤 다시 실행하세요" \
  bash -c '[ -n "$NAT_IP" ] && aws ec2 get-console-output --instance-id "$PRIV_ID" --latest --output text | grep -q "TF4D-NAT-CHECK egress_ip=$NAT_IP"'

# ---- 단계 2: EBS ----
check "EBS 볼륨이 웹 서버에 연결됨" \
  "aws_ebs_volume 과 aws_volume_attachment 를 만들었는지, AZ 가 웹 서버와 같은지 확인하세요" \
  bash -c '[ -n "$WEB_ID" ] && [ "$(aws ec2 describe-volumes --filters Name=tag:Day,Values=day3 Name=attachment.instance-id,Values="$WEB_ID" Name=status,Values=in-use --query "length(Volumes)" --output text)" -ge 1 ]'

# ---- 단계 3: 원격 state · state mv ----
check "backend 가 S3 로 설정됨" \
  "backend.tf 를 만들고 terraform init -migrate-state 를 실행했는지 확인하세요" \
  test "$BACKEND_TYPE" = "s3"

check "S3 에 state 파일이 있음" \
  "backend 버킷 이름과 key(day3/terraform.tfstate)를 확인하세요" \
  bash -c '[ -n "$BACKEND_BUCKET" ] && aws s3api head-object --bucket "$BACKEND_BUCKET" --key "$BACKEND_KEY"'

check "state mv 로 이름 변경 (data → web_data)" \
  "terraform state mv aws_ebs_volume.data aws_ebs_volume.web_data 후 코드의 이름도 바꿨는지 확인하세요" \
  bash -c 'grep -q "^aws_ebs_volume\.web_data$" <<< "$STATE" && ! grep -q "^aws_ebs_volume\.data$" <<< "$STATE"'

summary
echo " ※ Day 3 정리 순서: ~/day3 destroy → ~/day3-backend destroy → cleanup.sh → 작업용 EC2 중지"
