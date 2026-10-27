# Terraform-4days

Terraform 4일 온라인 과정의 실습 코드와 채점 스크립트 저장소입니다.
이론·실습 문서는 노션 **테라폼(4Days)** 페이지에서 제공합니다.

## 폴더 구성

```
Terraform-4days/
├── workstation/
│   └── user_data.sh      작업용 EC2 초기 설치 스크립트 (Amazon Linux 2023)
├── day1/ ~ day4/
│   ├── start/            그날 실습의 시작 코드
│   ├── solution/         정답 코드 (따라하기 버전과 동일)
│   └── backend/          (Day 3) state 보관용 S3 버킷 정답 코드
├── grade/
│   ├── day1.sh ~ day4.sh 일차별 채점 스크립트 (따라하기 버전 전용)
│   ├── cleanup.sh        정리 확인 - 남은 과금 리소스 점검
│   └── lib/              채점 공통 함수
└── README.md
```

## 실습 환경

| 항목 | 내용 |
|---|---|
| 리전 | `ap-northeast-2` (서울) |
| 작업용 서버 | EC2 t3.small / Amazon Linux 2023 / gp3 20GB |
| 접속 | 내 PC의 VS Code → Remote-SSH |
| AWS 인증 | 작업용 EC2에 연결한 IAM Role (Access Key를 만들지 않습니다) |

## 매일의 흐름

```bash
# 수업 시작: 콘솔에서 작업용 EC2 시작 → VS Code 접속 후
cd ~/Terraform-4days && git pull

# 실습 후 채점 (따라하기 버전)
bash ~/Terraform-4days/grade/day1.sh

# 정리
terraform destroy
bash ~/Terraform-4days/grade/cleanup.sh
# 마지막으로 콘솔에서 작업용 EC2 "중지"
```

## 주의

- 채점·정리 스크립트는 **조회만** 합니다. 리소스를 만들거나 지우지 않습니다.
- `terraform.tfvars`, `*.tfstate`, 키 파일(`*.pem`)은 절대 커밋하지 마세요.
