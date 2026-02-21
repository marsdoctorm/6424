# Use an Ubuntu base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install essential tools and libraries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    cmake \
    pkg-config \
    libreadline-dev \
    bison \
    flex \
    libfl-dev \
    iverilog \
    clang \
    libffi-dev \
    tcl-dev \
    python3 \
    python3-pip \
    python3-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-thread-dev \
    libgmp-dev \
    libjson-c-dev \
    zlib1g-dev \
    wget \
    autoconf \
    gperf \
    verilator \
    ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install yosys
RUN git clone --recursive https://github.com/YosysHQ/yosys.git /yosys && \
    cd /yosys && \
    make config-gcc && \
    make -j4 && \
    make install && \
    cd / && rm -rf /yosys

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Verify installation
RUN yosys -V && verilator -V

# Set up a working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]

