"""
Module to deploy a Hugging Face model (FashionCLIP) on Vertex AI.

Typical usage example from the command line:
    python cli.py --prepare
    python cli.py --deploy
    python cli.py --predict
"""

import os
import base64
import argparse
from glob import glob
import numpy as np
from google.cloud import storage
from google.cloud import aiplatform
from transformers import CLIPProcessor, CLIPModel

# Environment variables
GCP_PROJECT = os.environ["GCP_PROJECT"]
GCS_MODELS_BUCKET_NAME = os.environ["GCS_MODELS_BUCKET_NAME"]
MODEL_PATH = "models/model"
PROCESSOR_PATH = "models/processor"
ARTIFACT_URI = f"gs://{GCS_MODELS_BUCKET_NAME}"

def prepare():
    """
    Prepares the FashionCLIP model and processor by downloading from GCS
    and saving them in the correct format for Vertex AI deployment.
    """
    storage_client = storage.Client(project=GCP_PROJECT)

    # Local paths for storing model and processor
    local_model_path = "./artifacts/model"
    local_processor_path = "./artifacts/processor"

    if not os.path.exists(local_model_path):
        os.makedirs(local_model_path)
    if not os.path.exists(local_processor_path):
        os.makedirs(local_processor_path)

    # Download the model
    model_blob_path = "models/model/model.safetensors"
    config_blob_path = "models/model/config.json"
    bucket = storage_client.bucket(GCS_MODELS_BUCKET_NAME)
    
    # Download model.safetensors
    blob = bucket.blob(model_blob_path)
    blob.download_to_filename(os.path.join(local_model_path, "model.safetensors"))

    # Download config.json
    blob = bucket.blob(config_blob_path)
    blob.download_to_filename(os.path.join(local_model_path, "config.json"))

    # Download processor files
    processor_files = [
        "merges.txt",
        "preprocessor_config.json",
        "special_tokens_map.json",
        "tokenizer.json",
        "tokenizer_config.json",
        "vocab.json",
    ]

    for file_name in processor_files:
        processor_blob_path = f"models/processor/{file_name}"
        blob = bucket.blob(processor_blob_path)
        blob.download_to_filename(os.path.join(local_processor_path, file_name))

    print(f"Model and processor downloaded to {local_model_path} and {local_processor_path}")



def deploy():
    """
    Deploys the FashionCLIP model to Vertex AI and creates an endpoint.
    """
    serving_container_image_uri = "us-docker.pkg.dev/vertex-ai/prediction/pytorch-gpu.2-0:latest"

    # Path to the model artifacts
    model_artifact_path = f"{ARTIFACT_URI}/models/model"

    # Upload and deploy the model to Vertex AI
    deployed_model = aiplatform.Model.upload(
        display_name="FashionCLIP",
        artifact_uri=model_artifact_path,
        serving_container_image_uri=serving_container_image_uri,
    )
    print("Model uploaded:", deployed_model)

    # Deploy the model to an endpoint
    endpoint = deployed_model.deploy(
        deployed_model_display_name="FashionCLIPEndpoint",
        traffic_split={"0": 100},
        machine_type="n1-standard-4",  # Adjust based on your needs
        accelerator_type="NVIDIA_TESLA_T4",  # GPU support if needed
        accelerator_count=1,
        min_replica_count=1,
        max_replica_count=1,
    )
    print("Endpoint created:", endpoint)



def predict():
    """
    Uses the deployed FashionCLIP model for predictions.
    """
    # Endpoint format: "projects/{PROJECT_NUMBER}/locations/{REGION}/endpoints/{ENDPOINT_ID}"
    endpoint = aiplatform.Endpoint(
        "projects/{PROJECT_NUMBER}/locations/{REGION}/endpoints/{ENDPOINT_ID}"
    )

    # Sample image paths
    image_files = glob(os.path.join("data", "*.jpg"))
    print("Image files:", image_files[:5])

    # Select random images
    image_samples = np.random.choice(image_files, size=5, replace=False)
    for img_path in image_samples:
        print("Image:", img_path)
        with open(img_path, "rb") as f:
            data = f.read()
        b64str = base64.b64encode(data).decode("utf-8")

        # Prepare input for the model
        instances = [{"image": {"b64": b64str}}]
        response = endpoint.predict(instances=instances)

        # Print results
        print("Predictions:", response.predictions)


def main(args=None):
    if args.prepare:
        print("Preparing model...")
        prepare()

    elif args.deploy:
        print("Deploying model...")
        deploy()

    elif args.predict:
        print("Predicting using deployed endpoint...")
        predict()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FashionCLIP Deployment CLI")

    parser.add_argument(
        "--prepare",
        action="store_true",
        help="Prepare the FashionCLIP model and processor for Vertex AI.",
    )
    parser.add_argument(
        "--deploy",
        action="store_true",
        help="Deploy the FashionCLIP model to Vertex AI.",
    )
    parser.add_argument(
        "--predict",
        action="store_true",
        help="Make predictions using the deployed endpoint.",
    )

    args = parser.parse_args()
    main(args)
