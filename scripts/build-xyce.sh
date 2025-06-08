#!/bin/bash
set -e
set -o pipefail

mkdir -p "$ROOT/_build/Xyce"

CONFIGURE_OPTS="$@"

echo "Configuring Xyce $CONFIGURE_OPTS"

export LDFLAGS="-L$ARCHDIR/lib $LDFLAGS"
export CPPFLAGS="-I$ARCHDIR/include $CPPFLAGS"

# Get Trilinos libraries
TRILINOS_LIBS=$(for i in _build/libs/lib/*.a ; do basename $i ;done | sed -e 's/lib/-l/' -e 's/\.a//' | tr '\n' ' ')

pushd "$ROOT/_source/Xyce"
./bootstrap
popd

pushd "$ROOT/_build/Xyce"

$ROOT/_source/Xyce/configure \
--enable-mpi \
--enable-stokhos \
--enable-amesos2 \
$CONFIGURE_OPTS \
LIBS="$TRILINOS_LIBS" \
--prefix="$INSTALL_PATH" 2>&1 | tee "$ROOT/_build/Xyce-configure.log"

popd

echo "Building Xyce..."
NCPUS="${NCPUS:-$(nproc)}"
make -C _build/Xyce -j $NCPUS 2>&1 | tee "$ROOT/_build/Xyce-build.log"

