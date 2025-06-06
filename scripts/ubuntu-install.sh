#!/bin/bash
# Install dependencies using apt
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gfortran \
    cmake \
    bison \
    flex \
    libblas-dev \
    liblapack-dev \
    libfftw3-dev \
    libsuitesparse-dev \
    libopenmpi-dev \
    openmpi-bin \
    pkg-config \
    git


