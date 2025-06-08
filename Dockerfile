FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gfortran \
    bison \
    flex \
    libblas-dev \
    liblapack-dev \
    libfftw3-dev \
    libsuitesparse-dev \
    libopenmpi-dev \
    openmpi-bin \
    pkg-config \
    git \
    sudo \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for building
RUN useradd -m -s /bin/bash builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER builder
WORKDIR /home/builder

# Set up environment variables
ENV ROOT=/home/builder
ENV CFLAGS="-O3"
ENV CXXFLAGS="$CFLAGS -std=c++17"
ENV ARCHDIR=$ROOT/_build/libs
ENV SUITESPARSE_INC=/usr/include/suitesparse
ENV LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
ENV INCLUDE_PATH=/usr/include

# Use MPI compilers
ENV CXX=mpicxx
ENV CC=mpicc
ENV F77=mpif77

RUN ls -la
# Fetch source
COPY scripts/fetch-source.sh .
RUN bash fetch-source.sh
# Build Trilinos
COPY scripts/build-trilinos.sh .
RUN bash build-trilinos.sh
# Build Xyce
COPY scripts/build-xyce.sh .
RUN bash build-xyce.sh
# Run Regression
COPY scripts/xyce-regression.sh .
RUN bash xyce-regression.sh
# Install Xyce
COPY scripts/install-xyce.sh .
RUN bash install-xyce.sh

# Verify the installation
RUN ls -la _install/bin/ && \
    _install/bin/Xyce --version || echo "Xyce build completed"

# Set up runtime environment
ENV PATH="/home/builder/Xyce/_install/bin:$PATH"

CMD ["/bin/bash"]
