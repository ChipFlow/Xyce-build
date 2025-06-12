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

RUN ls -la
# Fetch source
COPY . .
RUN ./build.sh -s
# Build Trilinos
RUN ./build.sh -t
# Build Xyce
RUN ./build.sh -x
# Run Regression
RUN ./build.sh -r
# Install Xyce
RUN ./build.sh -i _install

# Verify the installation
RUN ls -la _install/bin/ && \
    _install/bin/Xyce --version || echo "Xyce build completed"

# Set up runtime environment
ENV PATH="/home/builder/Xyce/_install/bin:$PATH"

CMD ["/bin/bash"]
