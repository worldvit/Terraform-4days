data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ---------------------------------------------------------------
# ① state 보관용 S3 버킷
# ---------------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket        = "tf4d-day4-state-${local.account_id}"
  force_destroy = true # 실습용

  tags = { Name = "tf4d-day4-state" }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------
# ② GitHub OIDC 공급자: "GitHub이 발급한 신분증을 믿겠다"
#    계정에 이미 있으면 새로 만들지 않고 조회만 (count 로 조건부 생성)
# ---------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 0 : 1

  url = "https://token.actions.githubusercontent.com"
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}

# ---------------------------------------------------------------
# ③ GitHub Actions 가 맡을 IAM Role
#    - 내 저장소(github_owner/github_repo)의 워크플로만 이 Role 을 쓸 수 있음
# ---------------------------------------------------------------
data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "tf4d-day4-github-actions"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600
}

# infra 가 만드는 것: VPC · EC2 · ALB · ASG · CloudWatch → AmazonEC2FullAccess 에 모두 포함
resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# state 버킷만 읽고 쓰기 (lock 파일 포함)
data "aws_iam_policy_document" "state" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.state.arn}/day4/*"]
  }
}

resource "aws_iam_role_policy" "state" {
  name   = "tf4d-day4-state"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.state.json
}
