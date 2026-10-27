#!/bin/bash
# Day 2 채점 (따라하기 버전 전용)
# 사용법: 실습 폴더에서   bash ~/Terraform-4days/grade/day2.sh
#         다른 위치에서   bash ~/Terraform-4days/grade/day2.sh ~/day2
# ※ terraform destroy 하기 "전에" 실행하세요.

DIR="${1:-$PWD}"
STEPS=10
source "$(dirname "$0")/lib/common.sh"
require_tools
cd "$DIR" || { echo "폴더가 없습니다: $DIR"; exit 1; }

title "Day 2 채점 — 변수 하나로 웹서버 여러 대 만들기"
echo " 실습 폴더: $DIR"
echo

STATE=$(terraform state list 2>/dev/null)
IPS_JSON=$(terraform output -json server_ips 2>/dev/null || echo '{}')
COUNT=$(echo "$IPS_JSON" | jq 'length' 2>/dev/null || echo 0)
export STATE IPS_JSON

# 실습 태그(Day=day2)가 붙은 실행 중 인스턴스 ID 목록
RUNNING_IDS=$(aws ec2 describe-instances \
  --filters Name=tag:Course,Values=tf4d Name=tag:Day,Values=day2 Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null)

# ---- 공통 ----
check "terraform init 완료" \
  "실습 폴더에서 terraform init 을 실행했는지 확인하세요" \
  test -d .terraform

# ---- 단계 1: data source ----
check "data.aws_ami 로 AMI 조회" \
  "data.tf 에 data \"aws_ami\" 블록이 있고 apply 했는지 확인하세요" \
  bash -c 'grep -q "^data\.aws_ami\." <<< "$STATE"'

check "data 로 계정 · AZ 조회" \
  "data \"aws_caller_identity\" 와 data \"aws_availability_zones\" 블록이 있는지 확인하세요" \
  bash -c 'grep -q "^data\.aws_caller_identity\." <<< "$STATE" && grep -q "^data\.aws_availability_zones\." <<< "$STATE"'

check "단계 1의 연습용 서버(first) 삭제" \
  "ec2.tf 에서 aws_instance.first 블록을 지우고 apply 했는지 확인하세요" \
  bash -c '! grep -q "^aws_instance\.first" <<< "$STATE"'

# ---- 단계 2: for_each + dynamic ----
check "for_each 로 EC2 생성 (키 기반)" \
  "aws_instance 에 for_each = var.servers 를 썼는지 확인하세요 (state 에 [\"web\"] 처럼 보여야 함)" \
  bash -c 'grep -Eq "^aws_instance\.[a-z_]+\[\"web\"\]" <<< "$STATE" && grep -Eq "^aws_instance\.[a-z_]+\[\"app\"\]" <<< "$STATE"'

check "서버마다 보안 그룹 (for_each)" \
  "aws_security_group 에도 for_each = var.servers 를 썼는지 확인하세요" \
  bash -c '[ "$(grep -Ec "^aws_security_group\.[a-z_]+\[\"" <<< "$STATE")" -ge 2 ]'

check "dynamic 으로 인바운드 규칙 2개 이상" \
  "dynamic \"ingress\" 의 for_each = each.value.ports 를 확인하세요" \
  bash -c "n=\$(aws ec2 describe-security-groups --filters Name=tag:Course,Values=tf4d Name=tag:Day,Values=day2 Name=group-name,Values='*web*' --query 'SecurityGroups[0].IpPermissions | length(@)' --output text); [ \"\$n\" -ge 2 ]"

check "서버 2대 이상 실행 중" \
  "terraform apply 후 콘솔에서 인스턴스 상태를 확인하세요" \
  bash -c "[ \$(echo '$RUNNING_IDS' | wc -w) -ge 2 ]"

# ---- 단계 3: output(for) + templatefile ----
check "output server_ips (이름 => IP 맵)" \
  "outputs.tf 에 for 표현식으로 만든 output \"server_ips\" 가 있는지 확인하세요" \
  test "$COUNT" -ge 2

check "웹 페이지에 서버 이름이 보임" \
  "templatefile 로 user_data 를 넣었는지 확인하세요. 서버가 막 켜졌다면 2~3분 뒤 다시 실행하세요" \
  bash -c "ok=1; for k in \$(echo '$IPS_JSON' | jq -r 'keys[]'); do ip=\$(echo '$IPS_JSON' | jq -r --arg k \"\$k\" '.[\$k]'); curl -s -m 5 \"http://\$ip\" | grep -q \"<h1>\$k</h1>\" || ok=0; done; [ \$ok -eq 1 ]"

summary
