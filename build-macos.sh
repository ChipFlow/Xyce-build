ROOT=$(pwd)

brew install openblas cmake lapack bison flex fftw suitesparse autogen open-mpi
export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/lapack/lib/pkgconfig"
export PATH="$HOMEBREW_PREFIX/opt/bison/bin:$HOMEBREW_PREFIX/opt/flex/bin:$PATH"
export LDFLAGS="-L$HOMEBREW_PREFIX/opt/bison/lib -L$HOMEBREW_PREFIX/opt/flex/lib"
export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/bison/include -I$HOMEBREW_PREFIX/opt/flex/include"
export LDFLAGS="-L$HOMEBREW_PREFIX/opt/libomp/lib -L$HOMEBREW_PREFIX/lib $LDFLAGS"
export CPPFLAGS="-I/$HOMEBREW_PREFIX/opt/libomp/include -I$HOMEBREW_PREFIX/include/suitesparse -I$HOMEBREW_PREFIX/include $CPPFLAGS"
export CFLAGS="-O3 -fPIC"
export CXXFLAGS="-O3 -fPIC -std=c++17"

export LEX=$HOMEBREW_PREFIX/opt/flex/bin/flex
export BISON=$HOMEBREW_PREFIX/opt/bison/bin/bison
export CXX=mpicxx
export CC=mpicc
export F77=mpif77

export ARCHDIR=$ROOT/_build/libs

mkdir -p _build/trilinos
mkdir -p _build/install


cmake \
-DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpic++ \
-DCMAKE_Fortran_COMPILER=mpif77 \
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
-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
-DTrilinos_ENABLE_CXX11=ON \
-DTPL_ENABLE_AMD=ON \
-DTPL_ENABLE_BLAS=ON \
-DTPL_ENABLE_LAPACK=ON \
-DTPL_ENABLE_MPI=ON \
-DTPL_AMD_INCLUDE_DIRS=$HOMEBREW_PREFIX/include/suitesparse \
-DAMD_LIBRARY_DIRS=$HOMEBREW_PREFIX/lib \
-DCMAKE_INCLUDE_PATH=$HOMEBREW_PREFIX/include \
-DCMAKE_LIBRARY_PATH=$HOMEBREW_PREFIX/lib \
-DTrilinos_SET_GROUP_AND_PERMISSIONS_ON_INSTALL_BASE_DIR="$ARCHDIR" \
-DCMAKE_INSTALL_PREFIX=$ARCHDIR \
-S $ROOT/vendor/trilinos \
-B $ROOT/_build/trilinos

NCPUS=$(sysctl -n hw.logicalcpu)
make -C _build/trilinos -j $NCPUS
make -C _build/trilinos install

mkdir -p $ROOT/_build/xyce

export LDFLAGS="-L$ARCHDIR/lib -Wl,-framework,Accelerate $LDFLAGS"
export CPPFLAGS="-I$ARCHDIR/include $CPPFLAGS"

TRILINOS_LIBS=$(ls _build/libs/lib/*.a | xargs basename | sed -e 's/lib/-l/' -e 's/\.a//' | tr '\n' ' ')

cd $ROOT/_build/xyce && \
$ROOT/configure \
--enable-mpi \
--enable-stokhos \
--enable-amesos2 \
LIBS="$TRILINOS_LIBS" \
--prefix=$ROOT/_install

cd $ROOT
make -C _build/xyce -j $((NCPUS/2)) 2>&1 | tee _build/xyce-build.log
make -C _build/xyce install 2>&1 | tee _build/xyce-install.log
