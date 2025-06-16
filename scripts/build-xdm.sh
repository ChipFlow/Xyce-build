#!/bin/bash
set -e
set -o pipefail

mkdir -p "$ROOT/$BUILDDIR/Xyce"

mkdir -p $BUILDDIR/XDM
mkdir -p $BUILDDIR/install

CONFIGURE_OPTS="$@"
PYTHON=${PYTHON:-$(which python3)}

env > "$ROOT/$BUILDDIR/env-XDM.log"

echo "Configuring XDM $CONFIGURE_OPTS"
cmake \
-G"Unix Makefiles" \
-DCMAKE_INCLUDE_PATH="$INCLUDE_PATH" \
-DCMAKE_LIBRARY_PATH="$LIBRARY_PATH" \
-DCMAKE_INSTALL_PREFIX="$ARCHDIR" \
-DPython3_EXECUTABLE=$PYTHON \
-DCC="$CC" \
-DCXX="$CXX" \
$CONFIGURE_OPTS \
-S "$ROOT/_source/XDM" \
-B "$ROOT/$BUILDDIR/XDM" 2>&1 | tee "$ROOT/$BUILDDIR/configure-XDM.log"

echo "Building XDM..."
NCPUS="${NCPUS:-$(nproc)}"
make -C $BUILDDIR/XDM -j $NCPUS 2>&1 | tee "$ROOT/$BUILDDIR/build-XDM.log"

