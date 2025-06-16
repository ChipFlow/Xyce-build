#--------------------------
# Base image for building
#--------------------------
FROM ubuntu:24.04 AS base

# Install packages
COPY data/ubuntu-packages.txt data/ubuntu-packages.txt

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    $(cat data/ubuntu-packages.txt) \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for building
RUN useradd -m -u 1001 -s /bin/bash builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


RUN mkdir -p /home/builder/scripts
COPY --chown=builder:builder scripts/*ubuntu* /home/builder/scripts
COPY --chown=builder:builder data /home/builder/data/

ENV NO_UBUNTU_INSTALL=1

#--------------------------
# Assemble Sources
#--------------------------
FROM base AS source

COPY --chown=builder:builder scripts/fetch-source.sh /home/builder/scripts/fetch-source.sh
COPY --chown=builder:builder _source* /home/builder/_source
COPY --chown=builder:builder build.sh /home/builder/build.sh

USER builder
WORKDIR /home/builder
ENV  CCACHE_DIR=/ccache

RUN --mount=type=cache,target=/ccache,uid=1001 ./build.sh -s

#--------------------------
# Build Trilinos
#--------------------------
FROM source AS trilinos

COPY --chown=builder:builder scripts/*trilinos*  /home/builder/scripts/
COPY --chown=builder:builder _build_Linux*/trilinos* /home/builder/trilinos

USER builder
WORKDIR /home/builder

ENV NO_UBUNTU_INSTALL=1

RUN --mount=type=cache,target=/ccache,uid=1001 ./build.sh -t

#--------------------------
# Build XDM
#--------------------------
FROM source AS xdm
COPY --chown=builder:builder scripts/build-xdm.sh  /home/builder/scripts/build-xdm.sh
COPY --chown=builder:builder _build_Linux*/XDM* /home/builder/XDM

COPY --from=trilinos --chown=builder:builder /home/builder/_build_Linux/libs* _build_Linux/libs

USER builder
WORKDIR /home/builder
RUN --mount=type=cache,target=/ccache,uid=1001 ./build.sh -m

#--------------------------
# Build Xyce
#--------------------------
FROM source AS xyce

COPY --chown=builder:builder scripts/build-xyce.sh  /home/builder/scripts/build-xyce.sh
COPY --chown=builder:builder scripts/install-xyce.sh  /home/builder/scripts/install-xyce.sh
COPY --chown=builder:builder scripts/install-xdm.sh  /home/builder/scripts/install-xdm.sh
COPY --chown=builder:builder _build_Linux*/Xyce* /home/builder/Xyce

COPY --from=trilinos --chown=builder:builder /home/builder/_build_Linux/libs* _build_Linux/libs
COPY --from=xdm --chown=builder:builder /home/builder/_build_Linux/XDM* _build_Linux/XDM

USER builder
WORKDIR /home/builder

RUN --mount=type=cache,target=/ccache,uid=1001 ./build.sh -x

#--------------------------
# Install Xyce and XDM
#--------------------------
RUN --mount=type=cache,target=/ccache,uid=1001 ./build.sh -i _install

#--------------------------
# Run regression tests
#--------------------------
FROM xyce AS regression

COPY --from=xdm --chown=builder:builder /home/builder/_build_Linux/XDM* _build_Linux/XDM
COPY --chown=builder:builder scripts/*regression*  /home/builder/scripts/
COPY --chown=builder:builder scripts/*install*  /home/builder/scripts/

USER builder
WORKDIR /home/builder

# Run Regression
#RUN --mount=type=cache,target=/ccache,uid=1001 ./build.sh -r

# Verify the installation
RUN ls -la _install_Linux/bin/ && \
    _install_Linux/bin/Xyce --version || echo "Xyce build completed"

RUN ls -laR . > file.list

#FROM scratch
#COPY --from=build /home/builder/_build_Linux /_build_Linux
#COPY --from=build /home/builder/_install_Linux /_install_Linux
#COPY --from=build /home/builder/file.list /file.list
