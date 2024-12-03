import os
import json
import argparse
from google.cloud import storage
from tqdm import tqdm

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "../../../secret.json"

# Function to download images and JSON file from GCS
def download_from_gcs(gcs_json_path, gcs_image_dir, local_json_path, local_image_dir):
    client = storage.Client()

    # Download JSON file
    bucket_name, json_blob_path = gcs_json_path.replace(
        "gs://", "").split("/", 1)
    bucket = client.bucket(bucket_name)
    json_blob = bucket.blob(json_blob_path)
    os.makedirs(os.path.dirname(local_json_path), exist_ok=True)
    json_blob.download_to_filename(local_json_path)

    # Load JSON and filter first 100 items
    with open(local_json_path, 'r') as f:
        data = json.load(f)

    # Download images
    bucket_name, image_blob_prefix = gcs_image_dir.replace(
        "gs://", "").split("/", 1)
    blobs = client.list_blobs(bucket_name, prefix=image_blob_prefix)
    os.makedirs(local_image_dir, exist_ok=True)

    for blob in tqdm(blobs):
        for item in data:
            if blob.name.endswith(item['image']):
                local_path = os.path.join(
                    local_image_dir, os.path.basename(blob.name))
                blob.download_to_filename(local_path)
                # print(f"Downloaded {blob.name} to {local_path}")

# Parse arguments
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--json_path", type=str, default="gs://fashion_ai_data/captioned_data/women_shoes/2024-11-18_11-34-54/women_shoes.json",
                        help="Path to the JSON file in the GCP bucket.")
    parser.add_argument("--image_dir", type=str, default="gs://fashion_ai_data/scrapped_data/women_shoes/2024-11-18_11-34-54",
                        help="Path to the images directory in the GCP bucket.")
    parser.add_argument("--local_json_path", type=str, default="fashion_ai_data/captioned_data/women_shoes/2024-11-18_11-34-54/women_shoes.json",
                        help="Local path to save the downloaded JSON file.")
    parser.add_argument("--local_image_dir", type=str, default="fashion_ai_data/scrapped_data/women_shoes/2024-11-18_11-34-54",
                        help="Local directory to save the downloaded images.")
    return parser.parse_args()

# Main function
def main():
    args = parse_args()

    # Download data from GCS
    download_from_gcs(args.json_path, args.image_dir,
                      args.local_json_path, args.local_image_dir)

    print("Data download completed.")

if __name__ == "__main__":
    main()
