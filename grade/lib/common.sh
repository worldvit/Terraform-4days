#!/bin/bash
# 채점 스크립트 공통 함수
# - 모든 검사는 "조회만" 합니다. 리소스를 만들거나 지우지 않습니다.

export AWS_REGION="${AWS_REGION:-ap-northeast-2}"
export AWS_PAGER=""

PASS=0
TOTAL=0
STEP=0
STEPS="${STEPS:-0}"

c_ok=$'\e[32m'; c_ng=$'\e[31m'; c_dim=$'\e[2m'; c_off=$'\e[0m'

title() {
  echo
  echo "=============================================="
  echo " $1"
  echo "=============================================="
}

# check "설명" "힌트" 명령...
#   명령이 성공(종료 코드 0)하면 PASS, 실패하면 FAIL과 힌트 출력
check() {
  local desc="$1" hint="$2"; shift 2
  STEP=$((STEP + 1)); TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    printf "[%d/%d] %-36s ${c_ok}PASS${c_off}\n" "$STEP" "$STEPS" "$desc"
    PASS=$((PASS + 1))
  else
    printf "[%d/%d] %-36s ${c_ng}FAIL${c_off}\n" "$STEP" "$STEPS" "$desc"
    printf "      ${c_dim}→ 힌트: %s${c_off}\n" "$hint"
  fi
}

summary() {
  echo "----------------------------------------------"
  echo " 결과: ${PASS}/${TOTAL} 통과"
  if [ "$PASS" -eq "$TOTAL" ]; then
    echo " 🎉 모두 통과했습니다! 이제 terraform destroy 와 cleanup.sh 를 실행하세요."
  else
    echo " FAIL 항목의 힌트를 확인하고 다시 실행해 보세요."
  fi
  echo "----------------------------------------------"
}

# terraform output 값 읽기 (없으면 빈 문자열)
tf_out() {
  terraform output -raw "$1" 2>/dev/null || true
}

# state 안에 특정 리소스 종류가 있는지
state_has() {
  terraform state list 2>/dev/null | grep -q "^$1\."
}

require_tools() {
  for t in terraform aws jq; do
    command -v "$t" >/dev/null || { echo "필요한 프로그램이 없습니다: $t"; exit 1; }
  done
}
