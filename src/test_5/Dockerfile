FROM python:3.11-slim-bookworm

ARG DEBIAN_PACKAGES="build-essential git screen vim"

# Prevent apt from showing prompts
ENV DEBIAN_FRONTEND=noninteractive

# Python wants UTF-8 locale
ENV LANG=C.UTF-8

# Tell pipenv where the shell is
ENV PYENV_SHELL=/bin/bash

# Tell Python to disable buffering so we don't lose any logs
ENV PYTHONUNBUFFERED=1

# Ensure we have an up-to-date baseline, install dependencies, and
# create a user so we don't run the app as root
RUN set -ex; \
    for i in $(seq 1 8); do mkdir -p "/usr/share/man/man${i}"; done && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends $DEBIAN_PACKAGES && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir --upgrade pip && \
    pip install pipenv && \
    useradd -ms /bin/bash app -d /home/app -u 1000 -p "$(openssl passwd -1 Passw0rd)" && \
    mkdir -p /app && \
    mkdir -p /persistent && \
    chown app:app /persistent && \
    chown app:app /app

# Create the /src directory inside the container
RUN mkdir -p /src

# Switch to non-root user
USER app

# Set working directory for the app
WORKDIR /app

# Add Pipfile and Pipfile.lock to /app directory
ADD --chown=app:app Pipfile Pipfile.lock /app/

# Add the caption_generating.py file to the /app directory
ADD --chown=app:app caption_generating.py /app/

# Create the /app/credentials directory for the secret.json file
RUN mkdir -p /app/credentials

# Add the secret.json file to /app/credentials directory
ADD --chown=app:app secret.json /app/credentials/secret.json

# Add the .env file to the /app directory
ADD --chown=app:app .env /app/

# Add the test_images folder to the /app directory
ADD --chown=app:app scraped_raw_images /app/scraped_raw_images

# Install Python dependencies via Pipenv
RUN pipenv sync

# Install python-dotenv for loading .env
RUN pip install python-dotenv

# Read the GOOGLE_APPLICATION_CREDENTIALS from the .env file and set it as an environment variable
RUN python -c "from dotenv import load_dotenv; import os; load_dotenv('/app/.env'); print('Loaded .env')"

# Set the GOOGLE_APPLICATION_CREDENTIALS environment variable to point to the /app/credentials directory
ENV GOOGLE_APPLICATION_CREDENTIALS=/app/credentials/secret.json

# Set the command to run the Python script
CMD ["pipenv", "run", "python", "caption_generating.py"]
