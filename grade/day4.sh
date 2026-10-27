#!/bin/bash
# Day 4 채점 (따라하기 버전 전용)
# 사용법: 저장소 폴더(~/day4)에서   bash ~/Terraform-4days/grade/day4.sh
#         다른 위치에서            bash ~/Terraform-4days/grade/day4.sh ~/day4
# ※ 단계 4(GitHub Actions로 v2 배포)까지 마치고, terraform destroy 하기 "전에" 실행하세요.

DIR="${1:-$PWD}"
STEPS=13
source "$(dirname "$0")/lib/common.sh"
require_tools
cd "$DIR" || { echo "폴더가 없습니다: $DIR"; exit 1; }

title "Day 4 채점 — 모듈로 만든 웹서비스를 GitHub Actions로 배포"
echo " 저장소 폴더: $DIR"
echo

# ---- 미리 값 모으기 (조회만) ----
STATE=$(terraform -chdir=infra state list 2>/dev/null)
ALB_URL=$(terraform -chdir=infra output -raw alb_url 2>/dev/null)
ASG_NAME=$(terraform -chdir=infra output -raw asg_name 2>/dev/null)
BACKEND_TYPE=$(jq -r '.backend.type // empty' infra/.terraform/terraform.tfstate 2>/dev/null)
BACKEND_BUCKET=$(jq -r '.backend.config.bucket // empty' infra/.terraform/terraform.tfstate 2>/dev/null)
BACKEND_KEY=$(jq -r '.backend.config.key // empty' infra/.terraform/terraform.tfstate 2>/dev/null)
HAS_GH=0; command -v gh >/dev/null && gh auth status >/dev/null 2>&1 && HAS_GH=1
export STATE ALB_URL ASG_NAME BACKEND_TYPE BACKEND_BUCKET BACKEND_KEY HAS_GH

# ---- 단계 1: 모듈 ----
check "모듈 3개 작성 (network · security · web)" \
  "modules/network, modules/security, modules/web 폴더에 main.tf · variables.tf · outputs.tf 가 있는지 확인하세요" \
  bash -c 'for m in network security web; do for f in main variables outputs; do [ -f "modules/$m/$f.tf" ] || exit 1; done; done'

check "root 모듈이 모듈 3개를 사용" \
  "infra/main.tf 의 module 블록 3개를 apply 했는지 확인하세요 (state 에 module.network. 등)" \
  bash -c 'for m in network security web; do grep -q "^module\.$m\." <<< "$STATE" || exit 1; done'

# ---- 단계 2: ALB + ASG ----
check "ALB 로 웹 접속" \
  "output \"alb_url\" 을 확인하세요. ALB 가 막 만들어졌다면 2~3분 뒤 다시 실행하세요" \
  bash -c '[ -n "$ALB_URL" ] && curl -s -m 5 "$ALB_URL" | grep -q "tf4d day4"'

check "ASG 서버 2대 이상 InService" \
  "ASG 의 desired_capacity 와 대상 그룹 헬스 체크를 확인하세요" \
  bash -c '[ -n "$ASG_NAME" ] && [ "$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" --query "length(AutoScalingGroups[0].Instances[?LifecycleState==\`InService\`])" --output text)" -ge 2 ]'

check "ALB 가 여러 서버로 나눠 보냄" \
  "새로고침할 때 instance 값이 바뀌어야 합니다. 서버가 아직 healthy 가 아니면 잠시 뒤 다시 실행하세요" \
  bash -c 'ids=$(for i in $(seq 1 12); do curl -s -m 5 "$ALB_URL" | grep -o "i-[0-9a-f]*"; done | sort -u | wc -l); [ "$ids" -ge 2 ]'

# ---- 단계 3: backend + OIDC ----
check "state 버킷 · infra backend = S3" \
  "bootstrap 을 apply 하고 infra 에서 terraform init -migrate-state 를 실행했는지 확인하세요" \
  bash -c '[ "$BACKEND_TYPE" = "s3" ] && aws s3api head-object --bucket "$BACKEND_BUCKET" --key "$BACKEND_KEY"'

check "GitHub OIDC 공급자" \
  "bootstrap 의 aws_iam_openid_connect_provider 를 확인하세요" \
  bash -c 'aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text | grep -q "token.actions.githubusercontent.com"'

check "OIDC Role 이 내 저장소만 신뢰" \
  "Role tf4d-day4-github-actions 의 신뢰 정책에 repo:<내 ID>/<저장소>:* 조건이 있는지 확인하세요" \
  bash -c 'aws iam get-role --role-name tf4d-day4-github-actions --query "Role.AssumeRolePolicyDocument" --output json | grep -q "repo:"'

# ---- 단계 4: GitHub Actions ----
check "workflow 파일 (id-token: write)" \
  ".github/workflows/terraform.yml 에 permissions 의 id-token: write 가 있는지 확인하세요" \
  bash -c 'grep -Eq "id-token:[[:space:]]*write" .github/workflows/*.yml'

check "GitHub 저장소 변수 2개" \
  "gh variable set AWS_ROLE_ARN / TF_STATE_BUCKET 을 했는지 확인하세요 (gh auth login 필요)" \
  bash -c '[ "$HAS_GH" = 1 ] && v=$(gh variable list) && grep -q AWS_ROLE_ARN <<< "$v" && grep -q TF_STATE_BUCKET <<< "$v"'

check "PR 에서 plan 성공" \
  "Pull Request 를 열고 Actions 탭에서 plan 이 초록색인지 확인하세요" \
  bash -c '[ "$HAS_GH" = 1 ] && [ "$(gh run list --event pull_request --limit 1 --json conclusion -q ".[0].conclusion")" = "success" ]'

check "main 병합 후 apply 성공" \
  "PR 을 merge 한 뒤 Actions 탭에서 apply 가 초록색인지 확인하세요" \
  bash -c '[ "$HAS_GH" = 1 ] && [ "$(gh run list --branch main --event push --limit 1 --json conclusion -q ".[0].conclusion")" = "success" ]'

check "v2 가 배포됨" \
  "apply 후 서버 교체(instance refresh)에 5~8분 걸립니다. 잠시 뒤 다시 실행하세요" \
  bash -c 'for i in $(seq 1 6); do curl -s -m 5 "$ALB_URL" | grep -q "tf4d day4 v2" || exit 1; done'

summary
echo " ※ Day 4 정리 순서: infra destroy → bootstrap destroy → cleanup.sh → 작업용 EC2 중지"
