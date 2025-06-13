#!/bin/bash
set -e
set -o pipefail

mkdir -p $BUILDDIR/trilinos
mkdir -p $BUILDDIR/install

CONFIGURE_OPTS="$@"

echo "Configuring Trilinos $CONFIGURE_OPTS"
cmake \
-DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpicxx \
-DCMAKE_Fortran_COMPILER=mpif77 \
-DCMAKE_INCLUDE_PATH="$INCLUDE_PATH" \
-DCMAKE_LIBRARY_PATH="$LIBRARY_PATH" \
-DCMAKE_INSTALL_PREFIX="$ARCHDIR" \
-DTrilinos_ENABLE_Fortran=ON \
-DTrilinos_ENABLE_NOX=ON \
  -DNOX_ENABLE_LOCA=ON \
-DTrilinos_ENABLE_EpetraExt=ON \
  -DEpetraExt_BUILD_BTF=ON \
  -DEpetraExt_BUILD_EXPERIMENTAL=ON \
  -DEpetraExt_BUILD_GRAPH_REORDERINGS=ON \
-DTrilinos_ENABLE_TrilinosCouplings=ON \
-DTrilinos_ENABLE_Ifpack=ON \
-DTrilinos_ENABLE_Isorropia=ON \
-DTrilinos_ENABLE_AztecOO=ON \
-DTrilinos_ENABLE_Belos=ON \
-DTrilinos_ENABLE_Teuchos=ON \
-DTrilinos_ENABLE_COMPLEX_DOUBLE=ON \
-DTrilinos_ENABLE_Amesos=ON \
-DAmesos_ENABLE_KLU=ON \
-DTrilinos_ENABLE_Amesos2=ON \
-DAmesos2_ENABLE_KLU2=ON \
-DAmesos2_ENABLE_Basker=ON \
-DTrilinos_ENABLE_Sacado=ON \
-DTrilinos_ENABLE_Stokhos=ON \
-DTrilinos_ENABLE_Kokkos=ON \
-DKokkosClassic_DefaultNode:STRING="Kokkos::Compat::KokkosOpenMPWrapperNode" \
-DTrilinos_ENABLE_Zoltan=ON \
-DTrilinos_ENABLE_Tpetra=ON \
-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
-DTrilinos_ENABLE_CXX11=ON \
-DTrilinos_GENERATE_REPO_VERSION_FILE=OFF \
-DTPL_ENABLE_AMD=ON \
-DTPL_ENABLE_BLAS=ON \
-DTPL_ENABLE_LAPACK=ON \
-DTPL_ENABLE_MPI=ON \
-DTPL_AMD_INCLUDE_DIRS="$SUITESPARSE_INC" \
-DAMD_LIBRARY_DIRS="$LIBRARY_PATH" \
-DTrilinos_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR="$ARCHDIR" \
$CONFIGURE_OPTS \
-S "$ROOT/_source/trilinos" \
-B "$ROOT/$BUILDDIR/trilinos" 2>&1 | tee "$ROOT/$BUILDDIR/configure-trilinos.log"

echo "Building Trilinos..."
NCPUS="${NCPUS:-$(nproc)}"
make -C $BUILDDIR/trilinos -j $NCPUS 2>&1 | tee "$ROOT/$BUILDDIR/build-trilinos.log"
make -C $BUILDDIR/trilinos install

