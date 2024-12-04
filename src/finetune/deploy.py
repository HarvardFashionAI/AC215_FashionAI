"""
Module to upload a Hugging Face model (FashionCLIP) to the Hugging Face Hub.

Typical usage example from the command line:
    python cli.py --deploy --repo_name <repo_name> --model_path <model_path>
"""

import os
import argparse
from huggingface_hub import login, HfApi, delete_file, upload_folder, list_repo_files


def deploy(repo_name, model_path):
    """
    Uploads the model and associated files to a Hugging Face repository.

    Args:
        repo_name (str): The Hugging Face repository name.
        model_path (str): The local path to the model files.
    """
    hf_token = os.environ.get("HUGGINGFACE_KEY")
    if not hf_token:
        raise ValueError("Environment variable HUGGINGFACE_KEY is not set.")

    login(token=hf_token)

    # Initialize Hugging Face API
    api = HfApi()

    # Check if the repository exists
    try:
        repo_files = list_repo_files(repo_id=repo_name, token=hf_token)
        print(f"Repository {repo_name} found. Proceeding with upload.")
    except Exception as e:
        print(f"Repository {repo_name} does not exist. Creating a new repository.")
        api.create_repo(repo_id=repo_name, token=hf_token, repo_type="model", exist_ok=True)
        repo_files = []  # Empty repository, no files to list

    # Files to preserve
    files_to_preserve = [".gitattributes", "README.md"]

    # Delete files not in the preserve list
    for file_path in repo_files:
        if file_path not in files_to_preserve:
            delete_file(path_in_repo=file_path, repo_id=repo_name, token=hf_token)
            print(f"Deleted: {file_path}")

    # Upload all files from the local model folder
    upload_folder(
        folder_path=model_path,
        repo_id=repo_name,
        token=hf_token,
        commit_message="Updated model upload"
    )

    print(f"Model from {model_path} successfully uploaded to the repository: {repo_name}")



def main(args=None):
    if args.deploy:
        if not args.repo_name or not args.model_path:
            raise ValueError(
                "Both --repo_name and --model_path must be provided for deployment."
            )
        print("Deploying model...")
        deploy(args.repo_name, args.model_path)
    else:
        print("No action specified. Use --deploy with --repo_name and --model_path.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="FashionCLIP Deployment CLI")

    parser.add_argument(
        "--deploy",
        action="store_true",
        help="Deploy the FashionCLIP model to the Hugging Face Hub.",
    )
    parser.add_argument(
        "--repo_name",
        type=str,
        help="The name of the Hugging Face repository.",
    )
    parser.add_argument(
        "--model_path",
        type=str,
        help="The local path to the model files.",
    )

    args = parser.parse_args()
    main(args)
