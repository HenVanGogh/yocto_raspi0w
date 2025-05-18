#!/bin/bash
# Helper script to start Yocto build environment in Docker

# Set working directory to the location of this script
cd "$(dirname "$0")"

# Export the Yocto working directory
export YOCTO_WORKDIR=$(pwd)

echo "Starting Docker container for Yocto build..."
echo "Mounting current directory ($YOCTO_WORKDIR) to /workdir in container"

# Run the Docker container
docker run --rm -it \
  -v "${YOCTO_WORKDIR}":/workdir \
  crops/poky:ubuntu-22.04 \
  --workdir=/workdir

echo "Docker container exited."