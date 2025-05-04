#!/bin/bash
set -e

yum update -y

dnf update -y

dnf install -y docker

sudo systemctl enable docker

sudo systemctl start docker

usermod -a -G docker ec2-user

yum install -y awscli

AWS_REGION="ap-northeast-2"
ECR_REPO_NAME="rehasher-team/rehash-backend"
IMAGE_TAG="latest"
ACCOUNT_ID="215626476886"
IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker pull $IMAGE_URI

docker rm -f rehash-backend || true
# 7. 포트 80 바인딩 + 컨테이너 실행 (root 권한)

cd /home/ec2-user

docker run -d \
  --name rehash-backend \
  -p 80:3000 \
  --restart always \
  --env-file .env \
  $IMAGE_URI
