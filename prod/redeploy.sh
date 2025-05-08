#!/usr/bin/env bash
set -e

# --- 설정: 환경에 맞게 수정하세요 ---
AWS_REGION="ap-northeast-2"
ACCOUNT_ID="215626476886"
ECR_NAMESPACE="rehasher-team"
ECR_REPOSITORY="rehash-backend"
IMAGE_TAG="latest"
CONTAINER_NAME="rehash-backend"
# ------------------------------------

IMAGE_URI="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_NAMESPACE/$ECR_REPOSITORY:$IMAGE_TAG"

echo "[1/5] AWS ECR 로그인 ($AWS_REGION)"
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "[2/5] 기존 컨테이너 중단 및 제거 ($CONTAINER_NAME)"

docker stop "$CONTAINER_NAME"

docker rm -f "$CONTAINER_NAME" || true

echo "[3/5] 최신 이미지 Pull (no-cache)"
docker pull "$IMAGE_URI"

cd /home/ec2-user

echo "[4/5] 새로운 컨테이너 실행 ($CONTAINER_NAME)"
docker run -d \
  --name "$CONTAINER_NAME" \
  -p 80:8080 \
  --restart always \
  --env-file .env \
  "$IMAGE_URI"

echo "[5/5] 배포 완료: $CONTAINER_NAME → $IMAGE_URI"
