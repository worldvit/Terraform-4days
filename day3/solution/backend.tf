# state를 S3에 보관 (단계 3)
# - bucket 은 코드에 적지 않고 init 할 때 넣습니다. (부분 구성, partial configuration)
#     terraform init -migrate-state \
#       -backend-config="bucket=$(terraform -chdir=../day3-backend output -raw bucket)"
# - use_lockfile: S3에 .tflock 파일을 만들어 동시 실행을 막음 (DynamoDB 불필요)
terraform {
  backend "s3" {
    key          = "day3/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
  }
}
