#!/bin/bash
mkdir -p "$ROOT/_build/xyce"

echo "Configuring Xyce..."
export LDFLAGS="-L$ARCHDIR/lib $LDFLAGS"
export CPPFLAGS="-I$ARCHDIR/include $CPPFLAGS"

# Get Trilinos libraries
TRILINOS_LIBS=$(for i in _build/libs/lib/*.a ; do basename $i ;done | sed -e 's/lib/-l/' -e 's/\.a//' | tr '\n' ' ')

pushd "$ROOT/_source/xyce"
./bootstrap
popd

pushd "$ROOT/_build/xyce"

$ROOT/_source/xyce/configure \
--enable-mpi \
--enable-stokhos \
--enable-amesos2 \
$CONFIGURE_OPTS \
LIBS="$TRILINOS_LIBS" \
--prefix="$INSTALL_PATH"

popd

echo "Building Xyce..."
NCPUS="${NCPUS:-$(nproc)}"
make -C _build/xyce -j $NCPUS 2>&1 | tee "$ROOT/_build/xyce-build.log"

