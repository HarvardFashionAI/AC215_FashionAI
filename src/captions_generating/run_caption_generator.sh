#!/bin/bash
TODAY=$(date +'%Y-%m-%d %H:%M:%S')

# Load environment variables from the .env file
set -a
source .env
set +a

# Convert .env line endings if necessary
if file .env | grep -q CRLF; then
    dos2unix .env
fi

# Check if the image already exists
if ! docker images "$IMAGE_NAME" | awk '{ print $1 }' | grep -q "$IMAGE_NAME"; then
    echo "Image does not exist. Building..."
    docker build -t "$IMAGE_NAME" .  # Add build context (.)
else
    echo "Image already exists. Skipping build..."
fi

# Create temporary directories for captioned data, failed data, and intermediate results
mkdir -p "$CAPTIONING_METADATA" "$CAPTIONING_FAILED" "$CAPTIONING_INTERMEDIATE"

TEMP_CAPTIONING=$(realpath "$CAPTIONING_METADATA")_tmp
TEMP_FAILED=$(realpath "$CAPTIONING_FAILED")_tmp
TEMP_INTERMEDIATE=$(realpath "$CAPTIONING_INTERMEDIATE")_tmp

rm -rf "$TEMP_CAPTIONING" "$TEMP_FAILED" "$TEMP_INTERMEDIATE"
mkdir -p "$TEMP_CAPTIONING" "$TEMP_FAILED" "$TEMP_INTERMEDIATE"
rm -rf "$CAPTIONING_METADATA" "$CAPTIONING_FAILED" "$CAPTIONING_INTERMEDIATE"

# Run Docker container with necessary environment variables and volumes
docker run --rm -it \
    --env-file .env \
    -v "$(pwd)":/src \
    -v "$(realpath "$CREDENTIALS"):/src/secret.json:ro" \
    -v "$(realpath "$TEMP_CAPTIONING"):/app/output" \
    -v "$(realpath "$TEMP_FAILED"):/app/fail" \
    -v "$(realpath "$TEMP_INTERMEDIATE"):/app/intermediate" \
    -e GOOGLE_APPLICATION_CREDENTIALS="/src/secret.json" \
    "$IMAGE_NAME"


CONTAINER_EXIT_CODE=$?

# Check if the container ran successfully
if [ $CONTAINER_EXIT_CODE -ne 0 ]; then
    echo "The captioning container encountered an issue. Checking logs..."
    
    # Show the logs (from captioning.log)
    cat captioning.log

    # Cleanup temporary directories
    rm -rf "$TEMP_CAPTIONING" "$TEMP_FAILED" "$TEMP_INTERMEDIATE"

    # Attempt to restore old data from DVC
    echo "Aborting script due to container failure. Restoring old data from DVC..."
    if ! pipenv run dvc pull --force ; then
        echo "Failed to restore old data. Please check DVC remote."
        exit 1
    fi
    exit 1
else
    echo "The Docker container ran successfully, and output is stored in $TEMP_CAPTIONING."
    echo "Failed data is stored in $TEMP_FAILED."
    echo "Intermediate results are stored in $TEMP_INTERMEDIATE."
fi

# Move up two directories to access the appropriate paths
# Change directory and verify the current working directory
cd ../../
pwd

# Add the GCP bucket caption_images as the DVC remote (only needs to be done once)
pipenv run dvc remote add -d caption_remote gs://caption_images -f|--force

# Modify the DVC remote to include the credential path
pipenv run dvc remote modify --local caption_remote credentialpath src/captions_generating/secret.json
if [ $? -eq 0 ]; then
    echo "DVC remote 'caption_remote' modified successfully."
else
    echo "Failed to modify DVC remote. Aborting."
    exit 1
fi

# Add the temp directories to DVC after moving up the directory structure
pipenv run dvc add $(realpath "$TEMP_CAPTIONING")
if [ $? -eq 0 ]; then
    echo "Captioning metadata added to DVC successfully."
else
    echo "Failed to add captioning metadata to DVC. Aborting."
    exit 1
fi

pipenv run dvc add $(realpath "$TEMP_FAILED")
if [ $? -eq 0 ]; then
    echo "Failed data added to DVC successfully."
else
    echo "Failed to add failed data to DVC. Aborting."
    exit 1
fi

pipenv run dvc add $(realpath "$TEMP_INTERMEDIATE")
if [ $? -eq 0 ]; then
    echo "Intermediate results added to DVC successfully."
else
    echo "Failed to add intermediate results to DVC. Aborting."
    exit 1
fi

# Push data to DVC remote (use new caption_remote)
pipenv run dvc push --remote caption_remote
if [ $? -eq 0 ]; then
    echo "Data pushed to DVC remote 'caption_remote' successfully."
else
    echo "Failed to push data to DVC remote. Aborting."
    exit 1
fi
