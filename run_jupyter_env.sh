#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Set variables
IMAGE_NAME="jupyter_env"  # Hardcoded image name
CONTAINER_NAME="jupyter_env"  # Fixed container name
DIR_NAME="$IMAGE_NAME"  # Directory for the Dockerfile and related files
DOCKERFILE="$DIR_NAME/Dockerfile"
HOST_PORT=8888
CONTAINER_PORT=8888
WORKSPACE=$(pwd)  # Current directory as workspace

# Check if the Docker image exists
if docker images | grep -q "$IMAGE_NAME"; then
  echo "Docker image $IMAGE_NAME already exists."
else
  # Create a directory for the Dockerfile if it doesn't exist
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
fi

# Check if the Docker container exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
  echo "Docker container $CONTAINER_NAME already exists."

  # Check if the container is running
  if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Docker container $CONTAINER_NAME is already running."
  else
    echo "Starting the Docker container: $CONTAINER_NAME..."
    docker start "$CONTAINER_NAME"
  fi
else
  # Run the Docker container
  echo "Creating and running the Docker container: $CONTAINER_NAME..."
  docker run -d --name "$CONTAINER_NAME" -p $HOST_PORT:$CONTAINER_PORT -v $WORKSPACE:/workspace "$IMAGE_NAME"
fi

# Wait for the container to initialize
sleep 5

# Print the container logs
echo "Printing logs for Docker container: $CONTAINER_NAME..."
docker logs "$CONTAINER_NAME"

# Instructions
echo "To stop the container: docker stop $CONTAINER_NAME"
