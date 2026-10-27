#!/bin/bash
# Day 1 채점 (따라하기 버전 전용)
# 사용법: 실습 폴더에서   bash ~/Terraform-4days/grade/day1.sh
#         다른 위치에서   bash ~/Terraform-4days/grade/day1.sh ~/day1
# ※ terraform destroy 하기 "전에" 실행하세요.

DIR="${1:-$PWD}"
STEPS=9
source "$(dirname "$0")/lib/common.sh"
require_tools
cd "$DIR" || { echo "폴더가 없습니다: $DIR"; exit 1; }

title "Day 1 채점 — 나의 첫 Terraform 프로젝트"
echo " 실습 폴더: $DIR"
echo

BUCKET_ARN=$(tf_out bucket_arn)
BUCKET=${BUCKET_ARN##*:}
INSTANCE_ID=$(tf_out instance_id)

# ---- 공통 ----
check "terraform init 완료" \
  "실습 폴더에서 terraform init 을 실행했는지 확인하세요" \
  test -d .terraform

check "Provider 버전 고정(terraform.tf)" \
  "terraform.tf 의 required_providers 에 hashicorp/aws 가 있는지 확인하세요" \
  grep -rqs 'hashicorp/aws' --include='*.tf' .

# ---- 단계 1: IAM ----
check "IAM 그룹 tf4d-devops 존재" \
  "iam.tf 의 aws_iam_group 이름이 tf4d-devops 인지, terraform apply 를 했는지 확인하세요" \
  aws iam get-group --group-name tf4d-devops

check "사용자 tf4d-adam 이 그룹에 포함" \
  "aws_iam_user_group_membership 리소스로 사용자를 그룹에 넣었는지 확인하세요" \
  bash -c 'aws iam get-group --group-name tf4d-devops --query "Users[].UserName" --output text | grep -qw tf4d-adam'

# ---- 단계 2: S3 ----
check "output bucket_arn 출력" \
  "outputs.tf 에 output \"bucket_arn\" 이 있는지, apply 후 terraform output 으로 보이는지 확인하세요" \
  test -n "$BUCKET"

check "S3 버킷 버전 관리 Enabled" \
  "aws_s3_bucket_versioning 리소스의 status 가 \"Enabled\" 인지 확인하세요" \
  bash -c "[ \"\$(aws s3api get-bucket-versioning --bucket '$BUCKET' --query Status --output text)\" = Enabled ]"

check "S3 버킷에 Course=tf4d 태그" \
  "providers.tf 의 default_tags 블록에 Course = \"tf4d\" 가 있는지 확인하세요" \
  bash -c "aws s3api get-bucket-tagging --bucket '$BUCKET' --query 'TagSet[?Key==\`Course\`].Value' --output text | grep -qx tf4d"

# ---- 단계 3: EC2 ----
check "EC2 인스턴스 실행 중" \
  "ec2.tf 를 apply 했는지, output \"instance_id\" 가 있는지 확인하세요" \
  bash -c "[ \"\$(aws ec2 describe-instances --instance-ids '$INSTANCE_ID' --query 'Reservations[0].Instances[0].State.Name' --output text)\" = running ]"

check "EC2 유형이 tfvars 값과 일치" \
  "terraform.tfvars 에 instance_type 을 적고 variables.tf 의 변수를 ec2.tf 에서 사용했는지 확인하세요" \
  bash -c "want=\$(grep -E '^\s*instance_type' terraform.tfvars | sed -E 's/.*\"(.*)\".*/\1/'); got=\$(aws ec2 describe-instances --instance-ids '$INSTANCE_ID' --query 'Reservations[0].Instances[0].InstanceType' --output text); [ -n \"\$want\" ] && [ \"\$want\" = \"\$got\" ]"

summary
