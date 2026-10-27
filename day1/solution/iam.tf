# 단계 1: IAM 그룹과 사용자를 만들고, 사용자를 그룹에 넣습니다.
resource "aws_iam_group" "devops" {
  name = "tf4d-devops"
}

resource "aws_iam_user" "adam" {
  name = "tf4d-adam"
}

resource "aws_iam_user_group_membership" "adam_devops" {
  user   = aws_iam_user.adam.name
  groups = [aws_iam_group.devops.name]
}
