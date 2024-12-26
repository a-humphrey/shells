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

# Retrieve and print the Jupyter token using docker exec
echo "Fetching the Jupyter token..."
TOKEN=$(docker exec "$CONTAINER_NAME" bash -c "jupyter server list" | grep -oP '(?<=token=)[a-zA-Z0-9]+')
if [ -n "$TOKEN" ]; then
  echo "Access Jupyter Lab at: http://localhost:$HOST_PORT/?token=$TOKEN"
else
  echo "Failed to retrieve the Jupyter token. Check the container logs for details:"
  echo "docker logs $CONTAINER_NAME"
  exit 1
fi

# Instructions
echo "To stop the container: docker stop $CONTAINER_NAME"
