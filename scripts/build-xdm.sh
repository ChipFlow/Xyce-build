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
$CONFIGURE_OPTS \
-S "$ROOT/_source/XDM" \
-B "$ROOT/_build/XDM" 2>&1 | tee "$ROOT/_build/XDM-configure.log"

echo "Building XDM..."
NCPUS="${NCPUS:-$(nproc)}"
make -C _build/XDM -j $NCPUS 2>&1 | tee "$ROOT/_build/XDM-build.log"

