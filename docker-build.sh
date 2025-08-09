#!/bin/bash

# Force rebuild Docker image without cache
echo "Building Docker image with no cache to ensure latest files..."

# Generate a random cache bust value
CACHEBUST=$(date +%s)

# Build with no cache and cache bust argument
docker build --no-cache --build-arg CACHEBUST=$CACHEBUST -t adminer-custom .

echo "Build complete. To run:"
echo "docker run -d -p 3000:3000 adminer-custom"