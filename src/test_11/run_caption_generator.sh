#!/bin/bash
TODAY=$(date +'%Y-%m-%d %H:%M:%S')

rm -f intermediate_tmp.dvc fail_tmp.dvc output_tmp.dvc
if [ $? -eq 0 ]; then
    echo "Temporary DVC files removed successfully."
else
    echo "Failed to remove temporary DVC files."
fi

cd ../../

# Pull data from dvc
export GOOGLE_APPLICATION_CREDENTIALS="src/test_11/secret.json"
pipenv run dvc pull -r scraped_raw_data
mv data/scraped_raw_images src/test_11/scraped_raw_images

cd src/test_11

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
    -v "$(realpath "$TEMP_CAPTIONING"):/app/output" \
    -v "$(realpath "$TEMP_FAILED"):/app/fail" \
    -v "$(realpath "$TEMP_INTERMEDIATE"):/app/intermediate" \
    $IMAGE_NAME

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
pipenv run dvc remote add -d caption_remote gs://caption_images -f

# Modify the DVC remote to include the credential path
pipenv run dvc remote modify --local caption_remote credentialpath src/test_5/secret.json
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

# Pull the latest changes and rebase
pipenv run git stash
pipenv run git pull --rebase
if [ $? -ne 0 ]; then
    echo "Failed to pull and rebase from the remote repository. Aborting."
fi

# Add the DVC files for temp directories to Git
pipenv run git add $(realpath "$TEMP_CAPTIONING").dvc
if [ $? -ne 0 ]; then
    echo "Failed to add captioning DVC file to Git. Aborting."
fi

pipenv run git add $(realpath "$TEMP_FAILED").dvc
if [ $? -ne 0 ]; then
    echo "Failed to add failed DVC file to Git. Aborting."
fi

pipenv run git add $(realpath "$TEMP_INTERMEDIATE").dvc
if [ $? -ne 0 ]; then
    echo "Failed to add intermediate DVC file to Git. Aborting."
fi

# Commit the changes to Git
pipenv run git commit -m "Add DVC-tracked temp directories and captioned data for $TODAY"
if [ $? -ne 0 ]; then
    echo "Failed to commit changes to Git. Aborting."
fi

# Tag the commit with the current date and time
pipenv run git tag run-$(date +'%Y-%m-%d-%H-%M-%S')
if [ $? -ne 0 ]; then
    echo "Failed to create a Git tag. Aborting."
fi

# Push the changes to the yushu branch
pipenv run git push origin yushu
if [ $? -ne 0 ]; then
    echo "Failed to push changes to the yushu branch on the remote. Aborting."
fi

# Push the tags to the remote
pipenv run git push origin --tags
if [ $? -ne 0 ]; then
    echo "Failed to push tags to the remote repository. Aborting."
fi

echo "Git operations completed successfully."


# Push data to DVC remote (use new caption_remote)
export GOOGLE_APPLICATION_CREDENTIALS="src/test_11/secret.json"
pipenv run dvc push --remote caption_remote
if [ $? -eq 0 ]; then
    echo "Data pushed to DVC remote 'caption_remote' successfully."
else
    echo "Failed to push data to DVC remote. Aborting."
fi

# Cleanup temporary directories after DVC operations
rm -rf "$TEMP_CAPTIONING" "$TEMP_FAILED" "$TEMP_INTERMEDIATE"
if [ $? -eq 0 ]; then
    echo "Temporary directories cleaned up successfully."
else
    echo "Failed to clean up temporary directories."
fi

rm -rf .dvc/cache
if [ $? -eq 0 ]; then
    echo "DVC cache cleaned up successfully."
else
    echo "Failed to clean up DVC cache."
fi