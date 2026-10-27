#!/bin/bash
# 정리 확인: 서울 리전에 남아 있는 과금 리소스를 찾아 보여 줍니다.
# - 조회만 합니다. 아무것도 지우지 않습니다.
# - 작업용 EC2(태그 Role=workstation)는 점검 대상에서 제외합니다.
# 사용법: bash ~/Terraform-4days/grade/cleanup.sh

source "$(dirname "$0")/lib/common.sh"
command -v aws >/dev/null || { echo "aws CLI가 필요합니다"; exit 1; }

LEFT=0
report() {  # report "항목" "조회 결과(줄 단위)"
  local name="$1" items="$2"
  if [ -n "$items" ]; then
    printf "  ${c_ng}[남음]${c_off} %s\n" "$name"
    echo "$items" | sed 's/^/         - /'
    LEFT=1
  else
    printf "  ${c_ok}[정리됨]${c_off} %s\n" "$name"
  fi
}

title "정리 확인 — 리전 ${AWS_REGION}"

report "EC2 인스턴스 (작업용 EC2 제외)" "$(aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[].Instances[?!(Tags[?Key==`Role`&&Value==`workstation`])].[InstanceId,InstanceType,State.Name]' \
  --output text 2>/dev/null)"

report "NAT Gateway (시간당 과금)" "$(aws ec2 describe-nat-gateways \
  --filter Name=state,Values=pending,available \
  --query 'NatGateways[].[NatGatewayId,State]' --output text 2>/dev/null)"

report "Elastic IP" "$(aws ec2 describe-addresses \
  --query 'Addresses[].[PublicIp,AllocationId]' --output text 2>/dev/null)"

report "로드 밸런서 (ALB/NLB)" "$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[].[LoadBalancerName,State.Code]' --output text 2>/dev/null)"

report "Auto Scaling 그룹" "$(aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[].[AutoScalingGroupName,DesiredCapacity]' --output text 2>/dev/null)"

report "RDS 인스턴스" "$(aws rds describe-db-instances \
  --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]' --output text 2>/dev/null)"

report "EBS 볼륨 (어디에도 연결되지 않은 것)" "$(aws ec2 describe-volumes \
  --filters Name=status,Values=available \
  --query 'Volumes[].[VolumeId,Size]' --output text 2>/dev/null)"

report "IAM 사용자 · 그룹 · Role (tf4d-, 작업용 EC2 Role 제외)" "$( {
  aws iam list-users  --query 'Users[?starts_with(UserName, `tf4d-`)].UserName' --output text
  aws iam list-groups --query 'Groups[?starts_with(GroupName, `tf4d-`)].GroupName' --output text
  aws iam list-roles  --query 'Roles[?starts_with(RoleName, `tf4d-`) && RoleName!=`tf4d-workstation-role`].RoleName' --output text
} 2>/dev/null | tr '\t' '\n' | grep -v '^$')"

report "실습 태그(Course=tf4d)가 붙은 기타 리소스" "$(aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Course,Values=tf4d \
  --query 'ResourceTagMappingList[].ResourceARN' --output text 2>/dev/null | tr '\t' '\n' | grep -v '^$')"

echo
if [ "$LEFT" -eq 0 ]; then
  echo " ✅ 남은 실습 리소스가 없습니다."
else
  echo " ⚠️  [남음] 항목이 있습니다. 실습 폴더에서 terraform destroy 를 다시 실행하거나"
  echo "     콘솔에서 직접 삭제하세요. (삭제 직후에는 1~2분 동안 남아 보일 수 있습니다)"
fi

WS=$(aws ec2 describe-instances \
  --filters Name=tag:Role,Values=workstation Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null)
if [ -n "$WS" ]; then
  echo
  echo " 💡 작업용 EC2($WS)가 실행 중입니다. 수업이 끝났다면 콘솔에서 '중지'하세요."
fi
