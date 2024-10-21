# AC215 - Milestone2 - Fashion AI App

## Project Milestone 2 Organization

```

├── LICENSE
├── Pipfile
├── Pipfile.lock
├── README.md
├── data
│   ├── scraped_metadata
│   ├── scraped_metadata.dvc
│   ├── scraped_raw_images
│   └── scraped_raw_images.dvc
├── notebooks
│   ├── README.md
│   └── eda.ipynb
├── references
├── reports
│   ├── Fashion AI App Mock Screens.pdf
│   ├── Fashion AI ac215_proposal.pdf
│   ├── Prompts.text
│   ├── W&B Chart 10_19_2024, 10_13_28 PM (1).svg
│   ├── W&B Chart 10_19_2024, 10_13_28 PM (2).svg
│   ├── W&B Chart 10_19_2024, 10_13_28 PM (3).svg
│   └── Screenshot of running.png
│   └── AI stylist AI screen.png
│   └── Fashion shopper AI screen.png
├── src
│   ├── docker-compose.yml
│   ├── finetune
│   ├── inference
│   ├── caption
│   └── scraper
├── structure.txt


```


## Overview

**Team Members**
Yushu Qiu, Weiyue Li, Daniel Nurieli, Michelle Tan

**Group Name**
The Fashion AI Group

**Project**
Our goal is to create an AI-powered platform that aggregates fashion items from various brands, allowing users to quickly and easily find matching items without the hassle of endless browsing. Using our App, the users can put in a request such as "find me a classic dress for attending a summer wedding" and receive the clothing item that matches their request most closely. 

In future milestones, we will also attempt to implement an additional feature that leverages an AI styler to find matching items for existing clothing items they own.


## Milestone 2 Summary

For this milestone, we did the following: 
1. Scraped ~1,500 images and clothing items for men and women from the Farfetch website
2. Generated captions based on styles and potential events for the clothing images using Gemini API
3. Finetuned the Fashion CLIP model using the images alongside their captions

In our submission file, we have the components for data scraping, caption generation, Fashion CLIP finetuning, and Inference. 

**Data scraping**

We scraped a dataset of the URLs of 20k items from FarFetch (10k for men, 10k for women) of which we downloaded 1,500 clothing items(images) as we had to automate the image pulling pipeline. We plan on exanding this to additonal items for the final project. We have stored it in a private Google Cloud Bucket(real_size_data_bucket) which is sperate from the project since we wanted our continaers to be able to run on small scale for you to test. We also limited the number of images used in this current training dataset because of budget and processing speed limitations related to scraping and caption generation. We plan to expand our dataset for future milestones. We used Apify API to automate the scraping process.


**Caption generation**

We used Gemini 1.5 Flash model to come up with captions for the images used for training. Here is the prompt we used: "For this image, come up with a caption that has 4 parts, and uses short phrases to answer each of the four categories below: - the style - the occasions that it’s worn in - material used - texture and patterns."

Input: 1,500 scraped images
Output: Json file with captions and image names


**Fashion CLIP finetuning**


We fintuned the Fashion CLIP model in the finetune container. We first loaded the Fashion CLIP weights, then used our 1,500 images and their captions to perform the finetuning.

For hyperparameter optimization, we utilized Weights & Biases (WandB)'s sweep agent, leveraging a grid search to experiment with various combinations of learning rates ([5e-5, 5e-6, 1e-6]), epochs ([3, 5]), and batch sizes ([16, 32, 64]). Based on WandB's average loss chart, we selected the model with the best performance (overall loss after finetuning).

The optimal model was achieved with the following hyperparameters:

Batch size: 32
Epochs: 3
Learning rate: 5e-6

Regardless, we pushed all finetuned models to the cloud through DVC.

**Inference**

After finetuning the Fashion CLIP, we pull the best model from the cloud, load the weights, and find the best image that correspond's to a user's request based on objects, styles, and occasions.




## Virtual Environment Setup



Our project is assumed to be running on a host that will have a Pipefile in the main directory. All of our git and dvc requests are ran on that env. This env will ultimatly be a VM for our final project. 

To initialize the project, stay in the root directory of the repository and run `pipenv install`.

Here is a screenshot:

<a href="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/Screenshot%20of%20running.png">
    <img src="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/Screenshot%20of%20running.png" alt="Interactive SVG" width="568" height="367" />
</a>


## Versioned Data Strategy

We chose to use DVC as our versioned data strategy because it allows us to effectively track and manage large datasets within our fashion ai project, with Git integrating capabilities to version control our data alongside our code while keeping the Git repository lightweight and efficient. It is acting as a "Git for data" where we can easily access and revert to previous data versions when needed.

This project currently uses a single version of the dataset, collected on October 15 - 19, 2024.

- Data source: Farfetch website
- Collection date: October 15 - 19, 2024

## Instructions for running individual containers

Before running each individual containers, make sure you follow the instructions on the [Virtual Environment Setup](#Virtual-Environment-Setup) section and initialze the VM and the DVC for this project.

**Scraper container**
- This container has scripts for scraping and downloading images from Farfetch
- Instructions for running the model container - `pipenv install`

**Caption container**
- This container has scripts for labeling the data and add captions using Gemini's model
- Instructions for running the model container - `Instructions here`


**Finetuning container**
- This container has scripts for finetuning the Fashion CLIP model
- Instructions for running the model container - cd to the `src/finetune` directory and run `bash finetune.sh`.

**Inference container**
- This container has scripts for inference
- Instructions for running the model container - cd to the `src/inference` directory and run `bash inference.sh`

As discussed, the four dockers are run independently currently. We will add a docker compose file that manage all seperate containers in the future milestones.


## Files overview

### Scraper

1. **`src/scraper/scraper.py`**
   This script orchestrates scraping metadata and downloading images from Farfetch. It leverages the Apify API for crawling and downloading asynchronously, saving the results to local directories. Failed downloads are logged and stored in a separate CSV file. The script has two stages. Stage one involves getting the data into a csv file form the site. Second stage includes downloading the images given the url links. 
Apify has currently blocked our actor so we can't scrap or download. We plan to fix it moving forward. We didn't fix it for this submission as if we open a new acount we only have 3 days even if we pay($50) as we did. It cost $500 for an unlimited.

2. **`src/scraper/scraper.sh`**
  This script builds and runs a Docker container for scraping, manages temporary storage for metadata and images, and tracks the data with DVC. It also handles Git operations, committing and tagging the scraped data upon successful completion.

3. **`src/scraper/Pipfile`**
   We used the following packages to help with preprocessing on top of the common packages pandas, requests:
   - Apify
   - aiohttp
   - syncio
   - google-cloud-secret-manager

3. **`src/scraper/Dockerfile(s)`**
   Our Dockerfiles follow standard conventions.
   
### Caption


1. **`src/caption/caption_generating.py`**
   This script processes images by generating captions using Google's Gemini API. It retrieves the API key from Google Cloud's Secret Manager and checks for valid image formats like JPEG and PNG. For each image, the script generates captions based on style and material. It logs errors for failed images and saves results in both CSV and JSON formats. The script ensures output directories exist and tracks token usage. The captioning json are used for the model fine-tuning part.

2. **`src/caption/caption.sh`**
   This script automates scraping and data management. It builds and runs a Docker container, pulls data with DVC, and handles potential failures by restoring previous data. After scraping, it commits new data to DVC and Git and tags the run with the current date.

3. **`src/caption/Pipfile`**
   We used the following packages to help with preprocessing:
   - dvc
   - requests
   - pandas
   - google-cloud-storage
   - google-generativeai
   - google-cloud-secret-manager

4. **`src/caption/Dockerfile(s)`**
   Our Dockerfiles follow standard conventions.
   
### Finetuning


1. **`src/finetune/finetune.py`**
   This script fine-tunes the FashionCLIP model on a custom dataset, training it on image-caption pairs. It uses Wandb for experiment tracking and hyperparameter sweeps, and saves the fine-tuned model after training.

2. **`src/finetune/finetune.sh`**
   This script pulls models, checks if the Docker image exists (building it if needed), and runs the finetuning process in a Docker container, and manages DVC and Git updates for the trained models and data.

3. **`src/datapipeline/Pipfile`**
   We used the following packages to help with preprocessing:
   - torch
   - torchvision
   - transformers
   - Pillow
   - wandb
   - annoy
   - fashion-clip
   - google-cloud-secret-manager

4. **`src/inference/Dockerfile(s)`**
   Our Dockerfiles follow standard conventions.
   
### Inference

1. **`src/inference/qa.py`**
   This script searches for images that best match a given text query using a fine-tuned CLIP model. It processes images from a dataset, computes text-to-image similarities, and returns the image that most closely matches the provided query.

2. **`src/inference/inference.sh`**
   This script pulls the models from DVC, checks if the Docker image exists (building it if needed), and runs the inference process in a Docker container.

3. **`src/datapipeline/Pipfile`**
   We used the following packages to help with preprocessing:
   - torch
   - torchvision
   - transformers
   - Pillow
   - wandb
   - annoy
   - fashion-clip
   - google-cloud-secret-manager

4. **`src/inference/Dockerfile(s)`**
   Our Dockerfiles follow standard conventions.



## ML Model Experiments Log

Since we were only finetuning the model on the same dataset and the same model architecture, we only perform hyperparameter finetuning for our experiments. The below three figures show the average loss vs different batch sizes, numbers of epoch, and learning rates. We can see that the finetuned model has the best performance when we have batch size of 32, number of epoch of 3, and learning rate of 5e-6.

<a href="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/W%26B%20Chart%2010_19_2024%2C%2010_13_28%20PM%20(3).svg">
    <img src="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/W%26B%20Chart%2010_19_2024%2C%2010_13_28%20PM%20(3).svg" alt="Interactive SVG" width="600" height="460" />
</a>


<a href="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/W%26B%20Chart%2010_19_2024%2C%2010_13_28%20PM%20(1).svg">
    <img src="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/W%26B%20Chart%2010_19_2024%2C%2010_13_28%20PM%20(1).svg" alt="Interactive SVG" width="600" height="460" />
</a>


<a href="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/W%26B%20Chart%2010_19_2024%2C%2010_13_28%20PM%20(2).svg">
    <img src="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/W%26B%20Chart%2010_19_2024%2C%2010_13_28%20PM%20(2).svg" alt="Interactive SVG" width="600" height="460" />
</a>



## Mock-up of the Application

Below is our application mock-up. For our base use case (AI fashion shopper), our website will allow users to input a text prompt describing the items they're looking for, the occasion and style. The user will input their needs about fashion in the text box, and click the "Discover Now" button. 

We have an additional use case (AI stylist) where we plan to ask the users to input a text prompt describing what they're looking for, such as occasion and style, and to upload an image of an item they already own.

We will retrive the input text and the optional image from the app, load our finetuned model, and find an image along with some captions generated by the LM that match user's need from our database. The app will display our output images and the captions below the input boxes and button.

<a href="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/Fashion%20shopper%20AI%20screen.png">
    <img src="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/Fashion%20shopper%20AI%20screen.png" alt="Interactive SVG" width="900" height="367" />
</a>


<a href="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/AI%20stylist%20AI%20screen.png">
    <img src="https://github.com/weiyueli7/AC215_FashionAI/blob/main/reports/AI%20stylist%20AI%20screen.png" alt="Interactive SVG" width="561" height="367" />
</a>

