# state를 S3에 보관 (단계 3) — 작업용 EC2와 GitHub Actions가 같은 state를 씀
# bucket 은 init 할 때 넣습니다 (부분 구성)
#   작업용 EC2 : terraform init -migrate-state -backend-config="bucket=$(terraform -chdir=../bootstrap output -raw state_bucket)"
#   GitHub Actions: terraform init -backend-config="bucket=${{ vars.TF_STATE_BUCKET }}"
terraform {
  backend "s3" {
    key          = "day4/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
  }
}
