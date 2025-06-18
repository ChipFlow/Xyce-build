#!/bin/bash
set -e

export ROOT="$(pwd)"
echo "Building in $ROOT"

Help()
{
   # Display Help
   echo "Xyce build script for Ubuntu, Windows and macOS, 64 bit x86_64 or aarch64"
   echo
   echo "Syntax: $0 [-h] [-s] [-d] [-t] [-x] [-i install-dir] [-- [<configure flags>]]"
   echo "options:"
   echo "  -d:                Debug build"
   echo "  -s:                Fetch source"
   echo "  -t:                Build Trilinos"
   echo "  -m:                Build XDM"
   echo "  -x:                Build Xyce"
   echo "  -i:                Install XDM and Xyce in the given directory"
   echo "  -r:                Run the regression suite"
   echo "  -h:                Display this help"
   echo "  <configure flags>: Arbitary options to pass to ./configure :"
   echo
   ./configure --help | grep -e "\-\-enable" -e "\-\-disable" | grep -v -e "FEATURE" -e "--disable-option-checking"
}

#########
#Defaults
#########

if [ -n "$CI" ]; then
    echo "CI Detected"
fi

if [ -n "$DOCKER_BUILD" ]; then
    echo "Building in Docker"
fi

BUILD_TYPE=release
CFLAGS="-O3"
unset INSTALL_DEPS
unset FETCH_SOURCE
unset BUILD_TRILINOS
unset BUILD_XDM
unset BUILD_XYCE
unset RUN_REGRESSION
unset INSTALL_XYCE

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hdtxmsri:" option; do
  case $option in
    h) # display Help
        Help
        exit 0
        ;;
    d) # debug build
        BUILD_TYPE=debug
        CFLAGS="-g -O0"
        ;;
    s) # Fetch source only
        FETCH_SOURCE=1
        option_passed=1
        ;;
    t) # Build Trilinos only
        BUILD_TRILINOS=1
        option_passed=1
        ;;
    x) # Build Xyce only
        BUILD_XYCE=1
        option_passed=1
        ;;
    m) # Build XDM only
        BUILD_XDM=1
        option_passed=1
        ;;
    r) # Run regression for Xyce
        RUN_REGRESSION=1
        option_passed=1
        ;;
    i) # Install
        INSTALL_XYCE=1
        INSTALL_DIR=${OPTARG}
        option_passed=1
        ;;
    \?) # Invalid option
        echo "Error: Invalid option"
        echo
        Help
        exit
        ;;
  esac
done

# Default options
if [ -z $option_passed ]; then
  INSTALL_DEPS=1
  FETCH_SOURCE=1
  BUILD_TRILINOS=1
  BUILD_XDM=1
  BUILD_XYCE=1
  RUN_REGRESSION=1
  INSTALL_XYCE=1
fi


shift  $((OPTIND-1))

CONFIGURE_OPTS="$@"
TRILINOS_CONFIGURE_OPTS=""

case "$OSTYPE" in
  linux*)   OS="Linux" ;;
  darwin*)  OS="Darwin" ;;
  win*)     OS="Windows" ;;
  msys*)    OS="MSYS2" ;;
  cygwin*)  OS="Cygwin" ;;
  bsd*)     OS="BSD" ;;
  *)        echo "unknown: $OSTYPE" ;;
esac

echo "Determined that OS is $OS"
echo

if [[ "$OS" == "Linux" ]]; then
  if [ -e /etc/lsb-release ]; then
    DISTRO=$( cat /etc/lsb-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos)' | uniq )
  elif [ -e /etc/os-release ]; then
    DISTRO=$( cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos)' | uniq )
  else
    DISTRO='unknown'
  fi

  if [ -z $DISTRO ]; then
      DISTRO='unknown'
  fi

  if [[ "$DISTRO" == "ubuntu" ]]; then
    ./scripts/ubuntu-install.sh

    CFLAGS="$CFLAGS -Wno-deprecated-declarations"

    SUITESPARSE_INC=/usr/include/suitesparse
    LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
    INCLUDE_PATH=/usr/include
    export SUITESPARSE_INC LIBRARY_PATH INCLUDE_PATH

    BOOST_INCLUDEDIR=/usr/include/boost
    BOOST_LIBRARYDIR=/usr/lib/x86_64-linux-gnu
    CMAKE_CONFIG_DIR=/usr/lib/x86_64-linux-gnu/cmake
    MAKE="make"
    export BOOST_INCLUDEDIR BOOST_LIBRARYDIR CMAKE_CONFIG_DIR MAKE
  else
    echo "Unknown Linux distro - please figure out the packages to install and submit an issue!"
    exit 1
  fi
elif [[ "$OS" == "Darwin" ]]; then
  if [ -x /usr/local/bin/brew ];
    then eval $(/usr/local/bin/brew shellenv);
  elif [ -x /opt/homebrew/bin/brew ]; then
    eval $(/opt/homebrew/bin/brew shellenv);
  else
    echo "This currently only works for Homebrew. Feel free to submut a PR to support other MacOS packagers!"
    exit 1
  fi

  CFLAGS="$CFLAGS -Wno-unused-command-line-argument"

  HOMEBREW_NO_AUTO_UPDATE=1 brew install openblas cmake lapack bison flex fftw suitesparse autoconf automake libtool pkgconf open-mpi boost-python3 boost numpy scipy ccache
  PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/lapack/lib/pkgconfig:$HOMEBREW_PREFIX//opt/openblas/lib/pkgconfig"
  PATH="$HOMEBREW_PREFIX/opt/bison/bin:$HOMEBREW_PREFIX/opt/flex/bin:$HOMEBREW_PREFIX/opt/python/libexec/bin:$PATH"
  LDFLAGS="-L$HOMEBREW_PREFIX/opt/bison/lib -L$HOMEBREW_PREFIX/opt/flex/lib"
  CPPFLAGS="-I$HOMEBREW_PREFIX/opt/bison/include -I$HOMEBREW_PREFIX/opt/flex/include"
  LDFLAGS="-L$HOMEBREW_PREFIX/opt/libomp/lib -L$HOMEBREW_PREFIX/lib $LDFLAGS -L$HOMEBREW_PREFIX//opt/openblas/lib"
  CPPFLAGS="-I/$HOMEBREW_PREFIX/opt/libomp/include -I$HOMEBREW_PREFIX/include/suitesparse -I$HOMEBREW_PREFIX/include $CPPFLAGS -I$HOMEBREW_PREFIX//opt/openblas/include"
  LEX=$HOMEBREW_PREFIX/opt/flex/bin/flex
  BISON=$HOMEBREW_PREFIX/opt/bison/bin/bison
  MAKE="make"
  export PKG_CONFIG_PATH PATH LDFLAGS CPPFLAGS LEX BISON MAKE

  SUITESPARSE_INC=$HOMEBREW_PREFIX/include/suitesparse
  LIBRARY_PATH=$HOMEBREW_PREFIX/lib
  INCLUDE_PATH=$HOMEBREW_PREFIX/include
  BOOST_ROOT=$HOMEBREW_PREFIX
  export SUITESPARSE_INC LIBRARY_PATH INCLUDE_PATH BOOST_ROOT

  NCPUS=$(sysctl -n hw.logicalcpu)
  export NCPUS
elif [[ "$OS" == "Windows_MSYS2" || "$OS" == "Cygwin" ]]; then
  # check we have pacman
  pacman --version

  powershell -File ./scripts/set-path-length.ps1

  ./scripts/windows-install.sh

  CONFIGURE_OPTS="-DBLAS_LIBRARY_NAMES=openblas_64 -DBLAS_INCLUDE_DIRS=/ucrt64/include/openblas64 -DLAPACK_LIBRARY_NAMES=lapack64 -DCMAKE_OBJECT_PATH_MAX=10000"
  TRILINOS_CONFIGURE_OPTS="-DBLAS_LIBRARY_NAMES=openblas_64 -DBLAS_INCLUDE_DIRS=/ucrt64/include/openblas64 -DLAPACK_LIBRARY_NAMES=lapack64 -DCMAKE_OBJECT_PATH_MAX=10000"
  SUITESPARSE_INC=/ucrt64/include/suitesparse
  LIBRARY_PATH=/ucrt64/lib/x86_64-linux-gnu
  INCLUDE_PATH=/ucrt64/include
  BOOST_ROOT=/ucrt64
  BOOST_INCLUDEDIR=/ucrt64/include/boost
  BOOST_LIBRARYDIR=/ucrt64/lib/
  PYTHON=/ucrt64/usr/bin/python3
  MAKE=/ucrt64/bin/mingw32-make
  export SUITESPARSE_INC LIBRARY_PATH INCLUDE_PATH BOOST_ROOT BOOST_INCLUDEDIR BOOST_LIBRARYDIR MAKE

  # regression tests can take up to 2gb of ram, so limit max number
  REGRESSTION_MAX_CPUS=$(( $(awk '/MemTotal/ {print $2}' /proc/meminfo)  /  3000000  ))
  NCPUS=$NUMBER_OF_PROCESSORS
  CFLAGS="$CFLAGS -fpermissive"
  export NCPUS
else
  echo "Unknown environment"
fi

if [ -n "$FETCH_SOURCE" ]; then
  ./scripts/fetch-source.sh
fi

# Set up environment variables
export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CFLAGS -fPIC -std=c++17"

export CXX=mpicxx
export CC=mpicc
export F77=mpif77

export CCACHE=$(which ccache 2>/dev/null || echo '')
# Use MPI compilers
if [ -z "$CCACHE" ]; then
  echo "ccache not found"
else
  echo "ccache found, using $CCACHE"
  export CMAKE_C_COMPILER_LAUNCHER="$CCACHE"
  export CMAKE_CXX_COMPILER_LAUNCHER="$CCACHE"
fi

export BUILDDIR=_bld$OS
export ARCHDIR="$ROOT/$BUILDDIR/libs"

if [ -z "$INSTALL_PATH" ]; then
  INSTALL_PATH="$ROOT/_install_$OS"
fi
export INSTALL_PATH

if [ -n "$BUILD_TRILINOS" ]; then
  ./scripts/build-trilinos.sh $TRILINOS_CONFIGURE_OPTS || exit 1
fi

if [ -n "$BUILD_XDM" ]; then
  ./scripts/build-xdm.sh || exit 1
fi

if [ -n "$BUILD_XYCE" ]; then
  ./scripts/build-xyce.sh $CONFIGURE_OPTS || exit 1
fi

if [ -n "$RUN_REGRESSION" ]; then
  ./scripts/xyce-regression.sh $CONFIGURE_OPTS || exit 1
fi

if [ -n "$INSTALL_XYCE" ]; then
  export INSTALL_PATH="$INSTALL_PATH"
  ./scripts/install-xyce.sh || exit 1
  ./scripts/install-xdm.sh || exit 1
fi


