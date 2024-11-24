# AC215 - Milestone 4 - Fashion AI App

## Project Milestone 4 Organization

```plaintext
|-- README.md
|-- data
|   |-- .gitkeep
|   |-- sample_scrapped_images.dvc
|-- jest.config.js
|-- jest.setup.js
|-- notebooks
|   |-- .gitkeep
|   |-- README.md
|   `-- eda.ipynb
|-- references
|   `-- .gitkeep
|-- reports
|   |-- .gitkeep
|   |-- AI stylist AI screen.png
|   |-- Fashion AI App Mock Screens.pdf
|   |-- Fashion AI ac215_proposal.pdf
|   |-- Fashion shopper AI screen.png
|   |-- Screenshot of running.png
|   |-- W&B Chart 10_19_2024, 10_13_28 PM (1).svg
|   |-- W&B Chart 10_19_2024, 10_13_28 PM (2).svg
|   |-- W&B Chart 10_19_2024, 10_13_28 PM (3).svg
|   `-- W&B Chart 10_19_2024, 10_13_28 PM.svg
|-- src
|   |-- caption
|   |   |-- .env
|   |   |-- Dockerfile
|   |   |-- Pipfile
|   |   |-- Pipfile.lock
|   |   |-- caption.sh
|   |   |-- caption_generating.py
|   |   |-- output.dvc
|   |   |-- test_caption_generating.py
|   |   `-- test_main.py
|   |-- deployment_hf
|   |   |-- .gitignore
|   |   |-- Dockerfile
|   |   |-- Pipfile
|   |   |-- Pipfile.lock
|   |   |-- cli.py
|   |   |-- docker-entrypoint.sh
|   |   `-- docker-shell.sh
|   |-- finetune
|   |   |-- .env
|   |   |-- Dockerfile
|   |   |-- Pipfile
|   |   |-- Pipfile.lock
|   |   |-- cli.py
|   |   |-- cli.sh
|   |   |-- docker-entrypoint.sh
|   |   |-- finetune.py
|   |   |-- finetune.sh
|   |   |-- finetune_data.dvc
|   |   |-- models.dvc
|   |   |-- package-trainer.sh
|   |   |-- requirements.txt
|   |   |-- trainer.tar.gz
|   |   `-- wandb.dvc
|   |-- scraper
|   |   |-- .env
|   |   |-- Dockerfile
|   |   |-- Pipfile
|   |   |-- Pipfile.lock
|   |   |-- pytest.ini
|   |   |-- scraper.py
|   |   |-- scraper.sh
|   |   `-- test_scraper.py
|   |-- server
|   |   |-- .env
|   |   |-- backend
|   |   |   |-- Dockerfile
|   |   |   |-- Pipfile
|   |   |   |-- Pipfile.lock
|   |   |   |-- docker-shell.sh
|   |   |   |-- main.py
|   |   |   `-- test_main.py
|   |   |-- docker-compose-shell.sh
|   |   |-- docker-compose.yml
|   |   |-- frontend
|   |   |   |-- .env.development
|   |   |   |-- .env.production
|   |   |   |-- .gitignore
|   |   |   |-- .vscode
|   |   |   |   `-- launch.json
|   |   |   |-- Dockerfile
|   |   |   |-- Dockerfile.dev
|   |   |   |-- docker-shell.sh
|   |   |   |-- jsconfig.json
|   |   |   |-- next.config.js
|   |   |   |-- package-lock.json
|   |   |   |-- package.json
|   |   |   |-- postcss.config.js
|   |   |   |-- public
|   |   |   |-- src
|   |   |   |   |-- app
|   |   |   |   |   `-- stylist
|   |   |   |   |-- components
|   |   |   |   |   |-- layout
|   |   |   |   |   `-- stylist
|   |   |   |   `-- services
|   |   |-- integration_tests
|   |   |   `-- test_integration.py
|   |   |-- pinecone_service
|   |   |   |-- Dockerfile
|   |   |   |-- Pipfile
|   |   |   |-- Pipfile.lock
|   |   |   |-- docker-shell.sh
|   |   |   |-- main.py
|   |   |   `-- test_main.py
|   |   `-- vector_service
|   |       |-- Dockerfile
|   |       |-- Pipfile
|   |       |-- Pipfile.lock
|   |       |-- docker-shell.sh
|   |       |-- main.py
|   |       `-- test_main.py
|   `-- vectorized_db_init
|       |-- Dockerfile
|       |-- Pipfile
|       |-- Pipfile.lock
|       |-- data_buckets.csv
|       |-- docker-shell.sh
|       |-- helper_functions.py
|       |-- main.py
|       `-- test_main.py
```



## Overview

**Team Members**
Yushu Qiu, Weiyue Li, Daniel Nurieli, Michelle Tan

**Group Name**
The Fashion AI Group

**Project**
We are developing an AI-driven platform that consolidates fashion products from multiple brands, enabling users to efficiently discover matching items without the need for extensive searching. With our application, users can submit queries like "find me a classic dress for attending a summer wedding," and receive recommendations of clothing items that best fit their criteria.

## 1. Application Design Document

### Overview

Our application utilizes a server to access our fine-tuned FashionClip model and a vector database to process user text queries, returning recommended fashion items along with essential metadata. The design and architectural decisions outlined below are made to address these user requirements.

In the upcoming milestone, we plan to integrate a Large Language Model (LLM) agent to enhance the ways users can interact with the application.
![image](https://github.com/user-attachments/assets/389fbf27-7442-44b6-8fa5-929db0295a10)
![image](https://github.com/user-attachments/assets/8d554639-13eb-4aff-bb20-f5402a8b68fb)


---

### Solution Architecture

The Fashion AI application brings together several key components to ensure a smooth user experience. When the application is running, the `pinecone_service`, `vector_service`, backend, and frontend are all operational simultaneously. Users interact with the frontend via a web browser, sending requests to the backend API for fashion recommendations and stylist interactions.

During development, we also have additional components responsible for scraping raw images, generating captions for those images, and fine-tuning the FashionClip model with our new data.

The user interface details are provided in the frontend section below.

The main components, each located in a subfolder within the [`src/server`](src/server) directory, are:

1. **[`Frontend`](src/server/frontend)**: Built with Next.js, the frontend serves as the user interface, allowing users to interact with the AI stylist and browse fashion items.

2. **[`Backend`](src/server/backend)**: The backend contains the core API of the application. It handles incoming requests from the frontend, processes user queries, and communicates with the database and external services to provide fashion recommendations.

3. **[`Pinecone service`](src/server/pinecone_service)**: This directory includes the implementation for interfacing with Pinecone, a vector database service used for managing and querying high-dimensional data.

4. **[`Vector service`](src/server/vector_service)**: Responsible for handling vector representations of fashion items and performing similarity searches.


---

### Technical Architecture

#### Technologies and Frameworks

1. **[`Frontend`](src/server/frontend)**:
   - `Next.js`: A React framework for building server-rendered applications with features like static site generation and API routes.
   - `React`: A JavaScript library for creating user interfaces through reusable components.
   - `Tailwind CSS`: A utility-first CSS framework for styling, facilitating rapid UI development.
   - `Axios`: A promise-based HTTP client for making API requests from the frontend.

2. **[`Backend`](src/server/backend)**:
   - `Node.js`: A JavaScript runtime used for building the backend API, supporting asynchronous processing and scalability.
   - `FastAPI`: A modern Python framework for creating high-performance APIs, utilized for handling AI model requests and efficiently processing user queries.
   - `Pytest`: A testing framework for writing and executing unit tests to ensure the functionality and reliability of the backend API.

3. **Deployment**:
   - `Docker`: A platform for developing, shipping, and running applications in containers, ensuring consistency across different environments.

#### Design Patterns

- **MVC (Model-View-Controller)**: The application adheres to the MVC design pattern, separating concerns among the data model, user interface, and control logic.
- **Service Layer**: A service layer is implemented in the backend to handle business logic and API interactions, enhancing code reusability and promoting separation of concerns.
- **Component-Based Architecture**: The frontend is developed using a component-based architecture, allowing for modular development and easier maintenance.

---


## 2. Frontend and API Documentation

### Application Components

#### Frontend Components

1. **Pages**: The application features multiple pages, each corresponding to a specific route:
   - **Home Page**: Offers an introduction to the application and navigation links.
   - **Stylist Page**: Users can consult with the AI fashion stylist for tailored recommendations.
   - **Gallery Page**: Displays a collection of fashion items and styles.

2. **Components**: Includes reusable UI elements used across various pages:
   - **Buttons**: Custom button components for navigation and user actions.
   - **Image Gallery**: Presents images in a grid layout.
   - **Chat Input**: Allows users to input messages when interacting with the stylist.

3. **Services**: Modules responsible for API communications and data fetching, such as `DataService`, which interacts with the backend to obtain fashion items and stylist suggestions.

4. **Styles**: Utilizes Tailwind CSS for styling, providing responsive design capabilities and utility-first CSS classes.

#### API Components

The application leverages a set of APIs to manage communication between the frontend and backend. Key APIs include:

1. **Fetch Fashion Items**: Retrieves fashion items based on user input.
2. **Stylist Interaction**: Enables users to send messages to the AI stylist and receive personalized recommendations.

---

### Setup Instructions

To set up the Fashion AI application, follow these steps:


<!-- #### Frontend Setup -->

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/weiyueli7/AC215_FashionAI.git
   cd AC215_FashionAI/src/server
   ```
2. ** Run the Container**:
   ```bash
   sh docker-compose-shell.sh
   ```
The application will be available at `http://localhost:3000`.

<!-- 2. **Install Dependencies**:
   Ensure you have Node.js and npm installed. Then, install the required dependencies:
   ```bash
   npm install
   ```
3. **Start the Development Server**:
   To start the application in development mode:
   ```bash
   npm run dev
   ```
   The application will be available at `http://localhost:3000`. -->

<!-- #### API Setup

1. **Backend Service**: Ensure that the backend service is running and accessible. The frontend relies on the backend APIs to function correctly.

2. **API Configuration**: Make sure the API base URL is correctly set in the environment variables. This is typically done in the `.env.production` file. -->

---

### Usage Guidelines

#### Frontend Usage

- **Navigating the Application**: Use the navigation buttons on the home page to access different sections.
- **Interacting with the Stylist**: On the Stylist page, describe your occasion and style preferences to receive personalized recommendations.
- **Viewing the Gallery**: The Gallery page allows browsing through various fashion items. Click on any item for more details.

#### User Journey Showcase
- **Get Recommendation**:

    1. Click "Get Started Here" to access the AI Stylist page and receive personalized clothing recommendations.
    ![image](https://github.com/user-attachments/assets/7fc22823-04ee-4d5f-9d72-bbf13f5df2e6)

    2. Enter a query based on your preferences, such as "I want a pair of shoes."
    ![image](https://github.com/user-attachments/assets/5bf4ead4-2017-4cff-8464-fe5af095058d)

    3. The AI Assistant will provide a selection of shoe images tailored to your preferences, along with brand details and a brief description for each item.
    ![image](https://github.com/user-attachments/assets/a627ca5a-3692-415a-b565-6cf95d92524d)

    4. Click on the recommended image, and you will be redirected to the shopping link on Farfetch.
    ![image](https://github.com/user-attachments/assets/d1173bd0-084f-4ba1-9a82-545e7d33dcaf)

    
    
- **Explore Fashion Gallery**:

    1. Click on "Fashion Gallery" to explore a curated selection of clothing recommendations organized by category.
    ![image](https://github.com/user-attachments/assets/c49d5ef5-0d81-4374-8e4e-b282f70c08dc)

    2. For instance, if you're looking for Business Professional attire, navigate to the corresponding section to view tailored recommendations.
    ![image](https://github.com/user-attachments/assets/178684c4-5826-43e0-bdb8-8bdead870627)

    3. Click on any recommended image to be redirected to the shopping link on Farfetch.
    ![image](https://github.com/user-attachments/assets/c39ea621-00cc-4a7d-8b43-f1cee60b1913)



#### Frontend Usage

    {
        "items": [
            {
                "item_name": "string",
                "item_caption": "string",
                "image_url": "string",
                "item_url": "string",
                "item_brand": "string",
                "item_type": "string",
                "rank": "number",
                "score": "number"
            }
        ]
    }


## 3. Testing Document

#### CI Pipeline
This document outlines our group's implementation of a CI pipeline to automate code build, linting, testing, and reporting processes. The pipeline is integrated with GitHub Actions to run on every push or merge. We mainly tested the front end and back end parts instead of the model training part based on the instructions. We test the following components:

* **Build Testing:**
    **Purpose:**
    The build process ensures all Docker containers in the project are functional and properly configured. This step validates that containers are built successfully without errors.
    **Steps to Test Locally**
    1. Navigate to the /src/server folder
    2. Run ```sh docker-compose-shell.sh```

* **Lint Testing:**
    Linting is performed on all containers using Python to maintain code quality. We utilize flake8 as the linting tool to identify and fix potential code style issues.
    **Steps to Test Locally**
    1. Navigate to the folder you want to test (e.g. src/caption)
    2. Load Global Variables
        ```set -a```
        ```. src/server/.env```
        ```set +a```
    3. Install flake8 ```pip install flake8```
    4. Run ```flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics```
    
* **Unit Testing:**
    We implemented unit testing for both the caption component and the server component to ensure that all defined functions operate correctly. PyTest was used for this purpose, with test files placed in their respective folders.
    **Steps to Test Locally**
    1. Load Global Variables
        ```set -a```
        ```. src/server/.env```
        ```set +a```
    2. Run ```pytest --cov=. --cov-report=xml --cov-fail-under=50```
* **Integration Testing:**
    We implemented integration testing for the entire server (front end and back end) to ensure seamless interaction and a smooth connection between the two components.
    **Steps to Test Locally**
    1. Load Global Variables
        ```set -a```
        ```. src/server/.env```
        ```set +a```
    2. Run ```pytest src/server/integration_tests/test_integration.py -v```

<!-- #### Manual System Test
Other than automated testing, our repo also supports manual system testing. To do that, you can use the following steps:
1. Navigate to the /src/server folder
2. Run ```sh docker-compose-shell.sh```
3. Open your local browser and type `http://localhost:3000`
4. Then you can try different services available on the front end -->
