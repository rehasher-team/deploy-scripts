#!/bin/bash

set -e

yum update -y

yum install -y awscli

SECRET_ID="prod/rehasher/ec2"

cd $HOME

aws secretsmanager get-secret-value \
  --secret-id prod/rehasher/ec2 \
  --query SecretString \
  --output text | jq -r 'to_entries[] | "\(.key)=\(.value)"' > .env

echo "✅ $HOME 에 시크릿이 잘 저장되었습니다."
