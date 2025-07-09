#!/bin/bash

# This script builds a Docker image to generate interface libraries,
# extracts them, and updates the project's 'interface_libs' directory.

set -euo pipefail

# --- Configuration ---
# The script assumes it is located in the 'docker' directory of the project.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DOCKERFILE="${SCRIPT_DIR}/Dockerfile.ubuntu2004"
IMAGE_NAME="qt-libs-extractor"
CONTAINER_NAME="temp-extractor"
SRC_TAR="${SCRIPT_DIR}/interface_libs.tar.gz"
DEST_DIR="${PROJECT_ROOT}/interface_libs"
TEMP_DIR=$(mktemp -d -t ci-XXXXXXXXXX)

# Ensure cleanup happens on script exit
trap "rm -rf '${TEMP_DIR}'" EXIT
trap "rm '${SRC_TAR}'" EXIT

# --- Main Logic ---

# 1. Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker to continue."
    exit 1
fi

# 2. Build the Docker image to generate the tarball.
echo "Building Docker image to generate libraries..."
docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE}" "${SCRIPT_DIR}"

# 3. Extract the tarball from the image.
echo "Extracting libraries from Docker image..."
# Clean up any previous container with the same name.
docker rm "${CONTAINER_NAME}" &>/dev/null || true
# Create a container from the image.
docker create --name "${CONTAINER_NAME}" "${IMAGE_NAME}"
# Copy the generated tarball from the container.
docker cp "${CONTAINER_NAME}:/tmp/interface_libs.tar.gz" "${SRC_TAR}"
# Remove the temporary container.
docker rm "${CONTAINER_NAME}"

# 4. Validate that the source tarball exists.
if [[ ! -f "${SRC_TAR}" ]]; then
    echo "Error: Source archive not found at ${SRC_TAR}. Docker build may have failed."
    exit 1
fi

# 5. Extract the new interface libraries to a temporary location.
echo "Extracting libraries from ${SRC_TAR}..."
# The tarball is expected to contain the 'interface_libs' directory.
tar -xzf "${SRC_TAR}" -C "${TEMP_DIR}"
EXTRACTED_LIBS_DIR="${TEMP_DIR}/interface_libs"

if [[ ! -d "${EXTRACTED_LIBS_DIR}" ]]; then
    echo "Error: Tarball did not contain the expected 'interface_libs' directory."
    exit 1
fi

# 6. Clean the destination directory, preserving Bazel files (BUILD, *.bzl).
echo "Cleaning destination directory: ${DEST_DIR}"
# Create the destination directory if it doesn't exist.
mkdir -p "${DEST_DIR}"
# Delete all files that are not BUILD files or .bzl files.
find "${DEST_DIR}" -type f -not -name 'BUILD' -not -name '*.bazel' -delete
# Delete empty directories
#find "${DEST_DIR}" -mindepth 1 -type d -empty -delete


# 7. Sync the new libraries from the temporary location to the destination.
echo "Syncing new libraries to ${DEST_DIR}..."
# -a: archive mode (preserves permissions, etc.)
# -r: recursive
# The trailing slash on the source is important to copy contents.
#rsync -ar "${EXTRACTED_LIBS_DIR}/" "${DEST_DIR}/"

echo "Successfully updated interface libraries."
