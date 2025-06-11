#!/bin/bash
set -e
set -o pipefail

mkdir -p "$ROOT/_build/xyce"

mkdir -p _build/XDM
mkdir -p _build/install

CONFIGURE_OPTS="$@"

echo "Configuring XDM $CONFIGURE_OPTS"
cmake \
-DCMAKE_INCLUDE_PATH="$INCLUDE_PATH" \
-DCMAKE_LIBRARY_PATH="$LIBRARY_PATH" \
-DCMAKE_INSTALL_PREFIX="$ARCHDIR" \
-DPYTHON_INCLUDE_DIR=$(python -c "import sysconfig; print(sysconfig.get_path('include'))")  \
-DPYTHON_LIBRARY=$(python -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
$CONFIGURE_OPTS \
-S "$ROOT/_source/XDM" \
-B "$ROOT/_build/XDM" 2>&1 | tee "$ROOT/_build/configure-XDM.log"

echo "Building XDM..."
NCPUS="${NCPUS:-$(nproc)}"
make -C _build/XDM -j $NCPUS 2>&1 | tee "$ROOT/_build/build-XDM.log"

