#!/bin/bash
set -e

# 1. Docker 설치 (Amazon Linux 2 기준)
yum update -y

amazon-linux-extras install docker -y

service docker start

usermod -a -G docker ec2-user

chkconfig docker on

# 2. AWS CLI 설치
yum install -y awscli

# 3. 환경 변수 설정
AWS_REGION="ap-northeast-2"
ECR_REPO_NAME="rehasher-team/rehash-backend"
IMAGE_TAG="latest"
ACCOUNT_ID="215626476886"
IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"

# 4. ECR 로그인
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# 5. 이미지 Pull
docker pull $IMAGE_URI

# 6. 기존 컨테이너 종료 (중복 방지)
docker rm -f rehash-backend || true

# 7. 포트 80 바인딩 + 컨테이너 실행 (root 권한)
docker run -d \
  --name rehash-backend \
  -p 80:3000 \
  --restart always \
  $IMAGE_URI
