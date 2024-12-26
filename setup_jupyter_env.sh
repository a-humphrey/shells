#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if an image name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <image_name> <password>"
  exit 1
fi

# Check if a password is provided
if [ -z "$2" ]; then
  echo "Usage: $0 <image_name> <password>"
  exit 1
fi

# Set variables
IMAGE_NAME="$1"  # Use the first argument as the image name
PASSWORD="$2"  # Use the second argument as the password
DIR_NAME="$IMAGE_NAME"  # Directory for the Dockerfile and related files
DOCKERFILE="$DIR_NAME/Dockerfile"
CONTAINER_NAME="jupyter_env"  # Fixed container name
HOST_PORT=8888
CONTAINER_PORT=8888
WORKSPACE=$(pwd)  # Current directory as workspace

# Create a directory for the Dockerfile
if [ ! -d "$DIR_NAME" ]; then
  echo "Creating directory: $DIR_NAME"
  mkdir "$DIR_NAME"
else
  echo "Directory $DIR_NAME already exists"
fi

# Create the Dockerfile in the directory
cat <<EOF > $DOCKERFILE
# Use an official Python base image
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \\
    PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    build-essential \\
    libssl-dev \\
    libffi-dev \\
    curl \\
    git \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter, Polars, Plotly, and other commonly used Python libraries
RUN pip install --no-cache-dir \\
    jupyterlab \\
    numpy \\
    pandas \\
    matplotlib \\
    seaborn \\
    scikit-learn \\
    notebook \\
    ipywidgets \\
    polars \\
    plotly

# Configure Jupyter default password
RUN mkdir -p /root/.jupyter && \\
    echo "c.NotebookApp.password = \"\$(python3 -c 'from notebook.auth import passwd; print(passwd(\"$PASSWORD\"))')\"" > /root/.jupyter/jupyter_notebook_config.py

# Create a working directory
WORKDIR /workspace

# Expose Jupyter Notebook port
EXPOSE 8888

# Set default command to start Jupyter Lab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
EOF

# Build the Docker image
echo "Building the Docker image: $IMAGE_NAME..."
docker build -t "$IMAGE_NAME" "$DIR_NAME"

# Run the Docker container
echo "Running the Docker container: $CONTAINER_NAME..."
docker run -d --name "$CONTAINER_NAME" -p $HOST_PORT:$CONTAINER_PORT -v $WORKSPACE:/workspace "$IMAGE_NAME"

# Wait a moment to ensure the container starts
sleep 5

# Instructions
echo "Access Jupyter Lab at: http://localhost:$HOST_PORT with the password: $PASSWORD"
echo "To stop the container: docker stop $CONTAINER_NAME"
