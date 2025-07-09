#!/bin/bash

# This pretty much only deals with qt charts. Doesn't yet work with the base.

set -e

# Variables
QT_CHARTS_VERSION="6.9.1"
QT_CHARTS_URL="https://github.com/qt/qtcharts/archive/refs/tags/v${QT_CHARTS_VERSION}.tar.gz"
QT_SOURCE_DIR="../qt_source"
DOCKER_IMAGE_NAME="qt-builder"
TEMP_DIR=$(mktemp -d)

# 1. Download and extract qtcharts
echo "Downloading and extracting qtcharts ${QT_CHARTS_VERSION}..."
wget -qO- "${QT_CHARTS_URL}" | tar -xz -C "${TEMP_DIR}"
mv "${TEMP_DIR}/qtcharts-${QT_CHARTS_VERSION}" "${QT_SOURCE_DIR}/"
echo "qtcharts moved to ${QT_SOURCE_DIR}/"

# 2. Build the Docker image
echo "Building Docker image..."
docker build -t "${DOCKER_IMAGE_NAME}" .

# 3. Extract qt-builds.tar.gz from the Docker image
echo "Extracting qt-builds.tar.gz..."
CONTAINER_ID=$(docker create "${DOCKER_IMAGE_NAME}")
docker cp "${CONTAINER_ID}:/tmp/qt-builds.tar.gz" "${TEMP_DIR}/"
docker rm "${CONTAINER_ID}"

# 4. Extract the archive and copy the include folder
echo "Extracting archive and copying include folder..."
tar -xzf "${TEMP_DIR}/qt-builds.tar.gz" -C "${TEMP_DIR}"
cp -r "${TEMP_DIR}/qtcharts-build/include" "${QT_SOURCE_DIR}/qtcharts-${QT_CHARTS_VERSION}/"

# 5. Cleanup
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

echo "Script finished successfully."
