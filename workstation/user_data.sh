#!/bin/bash
# =====================================================================
#  Terraform 4일 과정 - 작업용 EC2 초기 설치 스크립트
#  대상: Amazon Linux 2023 / t3.small / 서울 리전(ap-northeast-2)
#
#  사용법: EC2 인스턴스 시작 화면 > 고급 세부 정보 > 사용자 데이터에
#          이 파일 내용을 그대로 붙여 넣습니다.
#  설치 로그: /var/log/tf4d-setup.log
#  설치 확인: 접속 후 `tf4d-env-check` 실행
# =====================================================================
set -euxo pipefail
exec > >(tee -a /var/log/tf4d-setup.log) 2>&1

STUDENT=ec2-user
HOME_DIR=/home/${STUDENT}
REGION=ap-northeast-2
COURSE_REPO=https://github.com/worldvit/Terraform-4days.git
# 특정 버전으로 고정하려면 아래 값을 바꿉니다. (예: TF_VERSION=1.13.4)
TF_VERSION=latest

# ---------------------------------------------------------------------
# 1. 시간대: 서울
# ---------------------------------------------------------------------
timedatectl set-timezone Asia/Seoul

# ---------------------------------------------------------------------
# 2. 기본 도구 (AWS CLI v2는 Amazon Linux 2023에 기본 설치되어 있음)
# ---------------------------------------------------------------------
dnf install -y git jq unzip tree

# GitHub CLI (Day 4: 저장소 만들기 · 로그인 · Actions 확인). 실패해도 설치는 계속
curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo -o /etc/yum.repos.d/gh-cli.repo \
  && dnf install -y gh || echo "gh 설치 실패: Day 4 실습 문서의 설치 명령으로 다시 설치하세요"

# ---------------------------------------------------------------------
# 3. Terraform 설치 (HashiCorp 공식 배포 파일)
# ---------------------------------------------------------------------
if [ "${TF_VERSION}" = "latest" ]; then
  TF_VERSION=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
fi
cd /tmp
curl -fsSLO "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip"
unzip -o "terraform_${TF_VERSION}_linux_amd64.zip" terraform -d /usr/local/bin
chmod 755 /usr/local/bin/terraform
rm -f "terraform_${TF_VERSION}_linux_amd64.zip"

# ---------------------------------------------------------------------
# 4. 스왑 1GB (메모리가 순간적으로 모자랄 때를 대비한 보조 메모리)
# ---------------------------------------------------------------------
if [ ! -f /swapfile ]; then
  dd if=/dev/zero of=/swapfile bs=1M count=1024
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile swap swap defaults 0 0' >> /etc/fstab
fi

# ---------------------------------------------------------------------
# 5. 수강생 계정 설정 (ec2-user)
#    - AWS CLI 기본 리전: 서울
#    - Terraform 플러그인 캐시: 일차별 폴더가 provider를 한 벌만 내려받아 공유
#    - 자주 쓰는 명령 별칭(alias)
# ---------------------------------------------------------------------
mkdir -p "${HOME_DIR}/.aws" "${HOME_DIR}/.terraform.d/plugin-cache"

cat > "${HOME_DIR}/.aws/config" <<EOF
[default]
region = ${REGION}
output = json
EOF

cat > "${HOME_DIR}/.terraformrc" <<'EOF'
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
EOF

if ! grep -q 'tf4d aliases' "${HOME_DIR}/.bashrc"; then
  cat >> "${HOME_DIR}/.bashrc" <<'EOF'

# ---- tf4d aliases ----
export AWS_REGION=ap-northeast-2
alias tf='terraform'
alias ti='terraform init'
alias tp='terraform plan'
alias ta='terraform apply'
alias td='terraform destroy'
complete -C /usr/local/bin/terraform terraform
EOF
fi

# ---------------------------------------------------------------------
# 6. 과정 저장소 내려받기
# ---------------------------------------------------------------------
if [ ! -d "${HOME_DIR}/Terraform-4days" ]; then
  git clone "${COURSE_REPO}" "${HOME_DIR}/Terraform-4days" || echo "저장소 clone 실패: 접속 후 직접 git clone 하세요"
fi

chown -R ${STUDENT}:${STUDENT} "${HOME_DIR}/.aws" "${HOME_DIR}/.terraform.d" "${HOME_DIR}/.terraformrc" "${HOME_DIR}/.bashrc"
[ -d "${HOME_DIR}/Terraform-4days" ] && chown -R ${STUDENT}:${STUDENT} "${HOME_DIR}/Terraform-4days"

# ---------------------------------------------------------------------
# 7. 설치 확인 명령: tf4d-env-check
# ---------------------------------------------------------------------
cat > /usr/local/bin/tf4d-env-check <<'EOF'
#!/bin/bash
ok()   { echo "  [OK]   $1"; }
fail() { echo "  [FAIL] $1"; FAILED=1; }
FAILED=0
echo "== 작업용 EC2 환경 점검 =="
command -v terraform >/dev/null && ok "Terraform  : $(terraform version | head -1)" || fail "Terraform이 설치되지 않았습니다"
command -v aws >/dev/null       && ok "AWS CLI    : $(aws --version 2>&1 | cut -d' ' -f1)" || fail "AWS CLI가 없습니다"
command -v git >/dev/null       && ok "git        : $(git --version)" || fail "git이 없습니다"
command -v gh >/dev/null        && ok "GitHub CLI : $(gh --version | head -1)" || echo "  [참고] GitHub CLI(gh) 없음 - Day 4 실습 문서 0단계에서 설치"
REGION_NOW=$(aws configure get region 2>/dev/null)
[ "${REGION_NOW}" = "ap-northeast-2" ] && ok "기본 리전  : ${REGION_NOW}" || fail "기본 리전이 ap-northeast-2가 아닙니다 (현재: ${REGION_NOW:-없음})"
ARN=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null) \
  && ok "AWS 인증   : ${ARN}" \
  || fail "AWS 인증 실패 - 인스턴스에 IAM Role(tf4d-workstation-role)이 연결되어 있는지 확인하세요"
swapon --show | grep -q swapfile && ok "스왑       : $(free -h | awk '/Swap/{print $2}')" || fail "스왑이 설정되지 않았습니다"
[ -d "$HOME/Terraform-4days" ] && ok "과정 저장소: ~/Terraform-4days" || fail "과정 저장소가 없습니다 (git clone https://github.com/worldvit/Terraform-4days.git)"
echo
[ ${FAILED} -eq 0 ] && echo "모든 항목 통과! 실습을 시작하세요." || echo "FAIL 항목을 확인하세요. 설치 로그: sudo tail -50 /var/log/tf4d-setup.log"
EOF
chmod 755 /usr/local/bin/tf4d-env-check

touch /var/log/tf4d-setup.done
echo "=== tf4d 작업용 EC2 설치 완료: $(date) ==="
