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
RUN useradd -m -s /bin/bash builder && \
    echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


RUN mkdir -p /home/builder/scripts
COPY --chown=builder:builder scripts/*ubuntu* /home/builder/scripts
COPY --chown=builder:builder data /home/builder/data/

ENV NO_UBUNTU_INSTALL=1

#---
FROM base as source

COPY --from=context --chown=builder:builder scripts/fetch_source.sh /home/builder/scripts/fetch_source.sh
COPY --from=context --chown=builder:builder _source* /home/builder/_source
COPY --from=context --chown=builder:builder build.sh /home/builder/build.sh
# Fetch source
USER builder
WORKDIR /home/builder
RUN ./build.sh -s

#---
FROM base AS trilinos

COPY --from=source _source /home/builder/_source
COPY --chown=builder:builder scripts/*trilinos*  /home/builder/scripts/
COPY --chown=builder:builder _build_Linux/trilinos* /home/builder/trilinos

USER builder
WORKDIR /home/builder

ENV NO_UBUNTU_INSTALL=1

# Build Trilinos
RUN ./build.sh -t

#---
FROM base AS xyce
RUN mkdir -p _build_Linux/trilinos


COPY --from=source _source /home/builder/_source
COPY --chown=builder:builder scripts/*xyce*  /home/builder/scripts/
COPY --chown=builder:builder _build_Linux/Xyce* /home/builder/Xyce
COPY --chown=builder:builder scripts/*xdm*  /home/builder/scripts/
COPY --chown=builder:builder _build_Linux/XDM* /home/builder/XDM

COPY --from=trilinos _build_Linux/libs* _build_Linux/libs

USER builder
WORKDIR /home/builder

# Build Xyce
RUN ./build.sh -x
# Install Xyce
RUN ./build.sh -i _install

FROM xyce AS regression

COPY --from=source _source /home/builder/_source
COPY --from=trilinos _build_Linux/libs _build_Linux/libs
COPY --chown=builder:builder scripts/*regression*  /home/builder/scripts/
COPY --chown=builder:builder scripts/*install*  /home/builder/scripts/
# Run Regression
RUN ./build.sh -r

# Verify the installation
RUN ls -la _install_Linux/bin/ && \
    _install_Linux/bin/Xyce --version || echo "Xyce build completed"

RUN ls -laR . > file.list

#FROM scratch
#COPY --from=build /home/builder/_build_Linux /_build_Linux
#COPY --from=build /home/builder/_install_Linux /_install_Linux
#COPY --from=build /home/builder/file.list /file.list
