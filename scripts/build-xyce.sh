#!/bin/bash
set -e
set -o pipefail

mkdir -p "$ROOT/$BUILDDIR/Xyce"

CONFIGURE_OPTS="$@"

echo "Configuring Xyce $CONFIGURE_OPTS"

if [ -n "$CCACHE" ]; then
  export CC="$CCACHE $CC"
  export CXX="$CCACHE $CXX"
fi
export LDFLAGS="-L$ARCHDIR/lib $LDFLAGS"
export CPPFLAGS="-I$ARCHDIR/include $CPPFLAGS"

# Get Trilinos libraries
TRILINOS_LIBS="-lisorropia -lzoltan -ltpetra -lkokkoskernels -lteuchosparameterlist -ltpetraclassic -lkokkoscore"

pushd "$ROOT/_source/Xyce"
./bootstrap
git apply $ROOT/data/*.patch

echo "Getting timedatestamp"
./utils/XyceDatestamp.sh "$ROOT/_source/Xyce"
echo
popd

pushd "$ROOT/$BUILDDIR/Xyce"

( $ROOT/_source/Xyce/configure \
--enable-mpi \
--enable-stokhos \
--enable-amesos2 \
$CONFIGURE_OPTS \
LIBS="$TRILINOS_LIBS" \
--prefix="$INSTALL_PATH" 2>&1 || cat config.log ) \
 | tee "$ROOT/$BUILDDIR/Xyce-configure.log"

popd

echo "Building Xyce..."
NCPUS="${NCPUS:-$(nproc)}"
echo "make -C $BUILDDIR/Xyce -j $NCPUS V=1 2>&1 | tee \"$ROOT/$BUILDDIR/Xyce-build.log\""
make -C $BUILDDIR/Xyce -j $NCPUS V=1 2>&1 | tee "$ROOT/$BUILDDIR/Xyce-build.log"

