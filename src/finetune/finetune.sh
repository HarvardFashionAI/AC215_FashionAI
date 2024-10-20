#!/bin/bash
TODAY=$(date +'%Y-%m-%d %H:%M:%S')

# Load environment variables from the .env file
export $(grep -v '^#' .env | xargs)

cd ../../
echo $PATH_TO_SECRET_KEY
export GOOGLE_APPLICATION_CREDENTIALS=$PATH_TO_SECRET_KEY
pipenv run dvc pull --remote fashion_ai_models --force

cd src/finetune

# Check if the image already exists
if ! docker images $IMAGE_NAME | awk '{ print $1 }' | grep -q $IMAGE_NAME; then
    echo "Image does not exist. Building..."
    docker build -t $IMAGE_NAME .
else
    echo "Image already exists. Skipping build..."
fi

# # Create temporary directories for scraped data
# TEMP_METADATA=$(realpath $SCRAPED_METADATA)_tmp
# TEMP_RAW_IMAGES=$(realpath $SCRAPED_RAW_IMAGES)_tmp

# # Ensure the temporary directories are empty
# rm -rf $TEMP_METADATA
# rm -rf $TEMP_RAW_IMAGES
# mkdir -p $TEMP_METADATA
# mkdir -p $TEMP_RAW_IMAGES


# Run the scraper container and redirect output to a log file
docker run --rm --name $IMAGE_NAME \
    -v $(pwd):/src \
    -v $(realpath ${SECRETS_PATH}${SECRET_FILE_NAME}):/secrets/$SECRET_FILE_NAME:ro \
    -e GOOGLE_APPLICATION_CREDENTIALS="/secrets/$SECRET_FILE_NAME" \
    $IMAGE_NAME

CONTAINER_EXIT_CODE=$?

# Check if the container ran successfully
if [ $CONTAINER_EXIT_CODE -ne 0 ]; then
    echo "The scraper container encountered an issue. Checking logs..."
    
    # # Show the logs (from scraper.log)
    # cat scraper.log

    # # Cleanup temporary directories
    # rm -rf $TEMP_METADATA
    # rm -rf $TEMP_RAW_IMAGES

    # cd ../../


    # # Attempt to restore old data from DVC
    # echo "Aborting script due to container failure. Restoring old data from DVC..."
    # if ! pipenv run dvc pull --force ; then
    #     echo "Failed to restore old data. Please check DVC remote."
    #     exit 1
    # fi
    exit 1
fi

# rm -rf $SCRAPED_METADATA/*
# rm -rf $SCRAPED_RAW_IMAGES/*

# if [ "$(ls -A $TEMP_METADATA)" ]; then
#     mv $TEMP_METADATA/* $(realpath $SCRAPED_METADATA)
#     echo "Copied contents from $TEMP_METADATA to $SCRAPED_METADATA."
# else
#     echo "No files to copy, $SOURCE_DIR is empty."
# fi

# if [ "$(ls -A $TEMP_RAW_IMAGES)" ]; then
#     mv $TEMP_RAW_IMAGES/* $(realpath $SCRAPED_RAW_IMAGES)
#     echo "Copied contents from $TEMP_RAW_IMAGES to $SCRAPED_RAW_IMAGES."
# else
#     echo "No files to copy, $SOURCE_DIR is empty."
# fi


# # Clean up temporary directories
# rm -rf $TEMP_METADATA
# rm -rf $TEMP_RAW_IMAGES

# Proceed with the rest of the script if no issues
pipenv run git stash
pipenv run git pull --rebase
pipenv run git stash pop
# Check if the pull created any conflicts
if [ $? -ne 0 ]; then
    echo "There was a merge conflict. Aborting script."
    exit 1
fi

cd ../../


# Add the scraped data to DVC only after ensuring there are no conflicts
pipenv run dvc add src/finetune/models
pipenv run dvc add src/finetune/finetune_data
pipenv run dvc add src/finetune/wandb

# Push data to DVC remote
export GOOGLE_APPLICATION_CREDENTIALS=$NEW_PATH_TO_SECRET_KEY
pipenv run dvc push --remote fashion_ai_models

# Commit the DVC changes to Git
pipenv run git add src/finetune/models.dvc
pipenv run git add src/finetune/finetune_data.dvc
pipenv run git add src/finetune/wandb.dvc
pipenv run git add $GIT_IGNORE

pipenv run git commit -m "finetuned models for $TODAY"

# Tag the run with the current date and time
pipenv run git tag run-$(date +'%Y-%m-%d-%H-%M-%S')

# Push the changes to Git
pipenv run git push origin main
pipenv run git push origin --tags

if [ $? -ne 0 ]; then
    echo "Failed to push changes to Git. Please resolve conflicts manually."
    exit 1
fi
