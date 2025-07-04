# Dockerfile to build Qt 6.9.0 from source on Ubuntu 22.04 (Jammy Jellyfish)

# Use the official Ubuntu 22.04 base image
FROM ubuntu:22.04

# Set environment variables to allow for non-interactive installation of packages
ENV DEBIAN_FRONTEND=noninteractive

# Set versions and configurations
ARG QT_VERSION=6.9.1
ARG QT_INSTALL_DIR=/opt/qt6

# Update package lists and install essential build tools and dependencies
# This is a comprehensive list required for a standard Qt build.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    ninja-build \
    git \
    wget \
    perl \
    python3 \
    libssl-dev \
    # X11 and OpenGL dependencies
    libfontconfig1-dev \
    libfreetype-dev \
    libgtk-3-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxcb-cursor-dev \
    libxcb-glx0-dev \
    libxcb-icccm4-dev \
    libxcb-image0-dev \
    libxcb-keysyms1-dev \
    libxcb-randr0-dev \
    libxcb-render-util0-dev \
    libxcb-shape0-dev \
    libxcb-shm0-dev \
    libxcb-sync-dev \
    libxcb-util-dev \
    libxcb-xfixes0-dev \
    libxcb-xkb-dev \
    libxcb1-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libxrender-dev \
    # Multimedia dependencies
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    libasound2-dev \
    # Other dependencies
    libdbus-1-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libicu-dev \
    libjpeg-dev \
    libpng-dev \
    libz-dev \
    libsqlite3-dev \
    libvulkan-dev \
    # Clean up apt cache to reduce image size
    && rm -rf /var/lib/apt/lists/*


# -------------------------- BUILD QTBASE --------------------------
# Set up a working directory for qtbase
WORKDIR /tmp

# Download the Qt source code
RUN QT_MAJOR_MINOR_VERSION=$(echo "${QT_VERSION}" | cut -d. -f1,2) && \
    wget https://github.com/qt/qtbase/archive/refs/tags/v${QT_VERSION}.tar.gz && \
    # Extract the source code
    tar xf v${QT_VERSION}.tar.gz && \
    # Remove the downloaded archive
    rm v${QT_VERSION}.tar.gz && \
    mkdir /tmp/qtbase-${QT_VERSION}/build

# Enter the source directory and configure the build
WORKDIR /tmp/qtbase-${QT_VERSION}/build

# Configure the Qt build.
# -prefix: The directory where Qt will be installed.
# -opensource: We are using the open-source version.
# -confirm-license: Automatically confirms the open-source license.
# -nomake examples/tests: Speeds up the build by not building examples and tests.
# You can add or remove modules from the -skip list as needed.
RUN ../configure \
    -release \
    -prefix ${QT_INSTALL_DIR} \
    -opensource \
    -confirm-license \
    -nomake examples \
    -nomake tests

# Build Qt using the number of available processor cores
RUN cmake --build . --parallel $(nproc)

# Install Qt
RUN cmake --install .

# Set Path to include Qt binaries for subsequent builds
ENV PATH="${QT_INSTALL_DIR}/bin:${PATH}"

# -------------------------- BUILD QTCHARTS --------------------------
# Set up a working directory for qtcharts
WORKDIR /tmp

# Download the qtcharts source code
RUN wget https://github.com/qt/qtcharts/archive/refs/tags/v${QT_VERSION}.tar.gz && \
    tar xf v${QT_VERSION}.tar.gz && \
    rm v${QT_VERSION}.tar.gz && \
    mkdir -p /tmp/qtcharts-${QT_VERSION}/build

# Enter the qtcharts build directory
WORKDIR /tmp/qtcharts-${QT_VERSION}/build

# Configure the qtcharts build using the already installed Qt
# CMAKE_PREFIX_PATH points to the location of the Qt installation
RUN cmake .. -D CMAKE_PREFIX_PATH=${QT_INSTALL_DIR} \
             -D CMAKE_BUILD_TYPE=Release

# Build qtcharts
RUN cmake --build . --parallel $(nproc)

# Install qtcharts into the same directory as qtbase
RUN cmake --install .

# -------------------------- FINALIZATION --------------------------

# Create an archive of the build directories for qtbase and qtcharts with custom folder names
RUN mkdir /tmp/staging && \
    mv /tmp/qtbase-${QT_VERSION}/build /tmp/staging/qtbase-build && \
    mv /tmp/qtcharts-${QT_VERSION}/build /tmp/staging/qtcharts-build && \
    tar -czf /tmp/qt-builds.tar.gz -C /tmp/staging .
