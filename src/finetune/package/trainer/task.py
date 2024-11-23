import os
import json
import argparse
from google.cloud import storage
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image
from transformers import CLIPModel, CLIPProcessor, AdamW
import torch
import wandb
from tqdm import tqdm

# Check if GPU is available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"\n\n\n\nUsing device: {device}\n\n\n\n\n")

# Define dataset class
class FashionDataset(Dataset):
    def __init__(self, json_file, image_dir, transform=None):
        with open(json_file, 'r') as f:
            self.data = json.load(f)  # Use all data points
        self.image_dir = image_dir
        self.transform = transform

    def __len__(self):
        return len(self.data)

    def __getitem__(self, idx):
        item = self.data[idx]
        image_path = os.path.join(self.image_dir, item['image'])
        image = Image.open(image_path).convert('RGB')
        if self.transform:
            image = self.transform(image)
        text = item['caption']
        return image, text


# Function to download images and JSON file from GCS
def download_from_gcs(gcs_json_path, gcs_image_dir, local_json_path, local_image_dir):
    client = storage.Client()

    # Download JSON file
    bucket_name, json_blob_path = gcs_json_path.replace("gs://", "").split("/", 1)
    bucket = client.bucket(bucket_name)
    json_blob = bucket.blob(json_blob_path)
    json_blob.download_to_filename(local_json_path)

    # Load JSON and extract all items
    with open(local_json_path, 'r') as f:
        data = json.load(f)

    # Download images
    bucket_name, image_blob_prefix = gcs_image_dir.replace("gs://", "").split("/", 1)
    blobs = client.list_blobs(bucket_name, prefix=image_blob_prefix)
    os.makedirs(local_image_dir, exist_ok=True)

    for blob in blobs:
        for item in data:
            if blob.name.endswith(item['image']):
                local_path = os.path.join(local_image_dir, os.path.basename(blob.name))
                blob.download_to_filename(local_path)
                print(f"Downloaded {blob.name} to {local_path}")

    return data


# Function to upload model weights to GCS
def upload_to_gcs(local_path, gcs_path):
    client = storage.Client()
    bucket_name, gcs_folder = gcs_path.replace("gs://", "").split("/", 1)
    bucket = client.bucket(bucket_name)

    for root, _, files in os.walk(local_path):
        for file in files:
            local_file_path = os.path.join(root, file)
            remote_path = os.path.join(gcs_folder, os.path.relpath(local_file_path, local_path))
            blob = bucket.blob(remote_path)
            blob.upload_from_filename(local_file_path)
            print(f"Uploaded {local_file_path} to {gcs_path}/{remote_path}")


# Parse arguments
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--category", type=str, required=True, help="Category to fine-tune on (e.g., men_clothes, women_shoes).")
    parser.add_argument("--output_dir", type=str, required=True, help="GCS path to save the fine-tuned model.")
    parser.add_argument("--batch_size", type=int, default=16, help="Training batch size.")
    parser.add_argument("--epochs", type=int, default=2, help="Number of training epochs.")
    parser.add_argument("--learning_rate", type=float, default=5e-6, help="Learning rate.")
    parser.add_argument("--wandb_key", dest="wandb_key", default="16", type=str, help="WandB API Key")
    return parser.parse_args()


def main():
    args = parse_args()

    wandb.login(key=args.wandb_key)
    wandb.init(project=f"fashionclip_{args.category}", config=args)

    # Define GCS paths based on the selected category
    gcs_json_path = f"gs://fashion_ai_data/captioned_data/{args.category}/2024-11-18_11-34-54/{args.category}.json"
    gcs_image_dir = f"gs://fashion_ai_data/scrapped_data/{args.category}/2024-11-18_11-34-54/"

    # Local paths for data
    local_json_path = "local_data.json"
    local_image_dir = "local_images"
    local_model_dir = "local_fine_tuned_model"

    # Create directories for model saving
    os.makedirs(local_model_dir, exist_ok=True)

    # Download data from GCS
    download_from_gcs(gcs_json_path, gcs_image_dir, local_json_path, local_image_dir)

    # Dataset and DataLoader
    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
    ])
    dataset = FashionDataset(json_file=local_json_path, image_dir=local_image_dir, transform=transform)
    dataloader = DataLoader(dataset, batch_size=args.batch_size, shuffle=True)

    # Model and processor
    model = CLIPModel.from_pretrained("patrickjohncyh/fashion-clip")
    processor = CLIPProcessor.from_pretrained("patrickjohncyh/fashion-clip")
    model.to(device)

    # Optimizer
    optimizer = AdamW(model.parameters(), lr=args.learning_rate)

    # Training loop
    for epoch in range(args.epochs):
        model.train()
        total_loss = 0
        progress_bar = tqdm(enumerate(dataloader), total=len(dataloader), desc=f"Epoch {epoch+1}/{args.epochs}")
        for batch_idx, (images, texts) in progress_bar:
            images = images.to(device)
            inputs = processor(text=texts, images=images, return_tensors="pt", padding=True, truncation=True).to(device)
            outputs = model(**inputs)
            logits_per_image = outputs.logits_per_image
            logits_per_text = outputs.logits_per_text
            loss_image = torch.nn.functional.cross_entropy(logits_per_image, torch.arange(len(images), device=device))
            loss_text = torch.nn.functional.cross_entropy(logits_per_text, torch.arange(len(texts), device=device))
            loss = (loss_image + loss_text) / 2
            total_loss += loss.item()
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            progress_bar.set_postfix(loss=loss.item())
            wandb.log({"epoch": epoch, "batch_idx": batch_idx, "loss": loss.item()})
        wandb.log({"epoch": epoch, "average_loss": total_loss / len(dataloader)})

    # Save and upload the model
    model.save_pretrained(local_model_dir)
    processor.save_pretrained(local_model_dir)
    upload_to_gcs(local_model_dir, args.output_dir)

    print(f"Fine-tuning on {args.category} completed and model uploaded successfully.")


if __name__ == "__main__":
    main()
