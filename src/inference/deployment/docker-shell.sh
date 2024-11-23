#!/bin/bash

set -e

export IMAGE_NAME=fashionclip-deployment-cli
export BASE_DIR=$(pwd)
export SECRETS_DIR=$(pwd)/../../../../secrets/
export GCP_PROJECT="fashion-ai-438801"
export GCS_MODELS_BUCKET_NAME="vertexai_train"


# Build the image based on the Dockerfile
#docker build -t $IMAGE_NAME -f Dockerfile .
# M1/2 chip macs use this line
docker build -t $IMAGE_NAME --platform=linux/arm64/v8 -f Dockerfile .

# Run Container
docker run --rm --name $IMAGE_NAME -ti \
-v "$BASE_DIR":/app \
-v "$SECRETS_DIR":/secrets \
-e GOOGLE_APPLICATION_CREDENTIALS=/secrets/secret.json \
-e GCP_PROJECT=$GCP_PROJECT \
-e GCS_MODELS_BUCKET_NAME=$GCS_MODELS_BUCKET_NAME \
$IMAGE_NAME