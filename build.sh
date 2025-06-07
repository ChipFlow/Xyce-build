#!/bin/bash -xv
set -e

export ROOT=$(pwd)
echo "Building in $ROOT"

Help()
{
   # Display Help
   echo "ngspice build script for macOS, 64 bit x86_64 or aarch64"
   echo
   echo "Syntax: $0 [-h] [-s] [-d] [-t] [-x] [-i install-dir] [-- [<configure flags>]]"
   echo "options:"
   echo "  -d:                Debug build"
   echo "  -s:                Fetch source"
   echo "  -t:                Build Trilinos only"
   echo "  -x:                Build Xyce only"
   echo "  -i:                Install Xyce in the given directory"
   echo "  -h:                Display this help"
   echo "  <configure flags>: Arbitary options to pass to ./configure :"
   echo
   ./configure --help | grep -e "\-\-enable" -e "\-\-disable" | grep -v -e "FEATURE" -e "--disable-option-checking"
}

#########
#Defaults
#########

INSTALL_DEPS=1
FETCH_SOURCE=1
BUILD_TRILINOS=1
BUILD_XYCE=1
INSTALL_XYCE="$ROOT/_install"
BUILD_TYPE=release
CFLAGS="-O3"
CONFIGURE_OPTS=""

echo GETOPTS

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hdtxsi:" option; do
  case $option in
    h) # display Help
        Help
        ;;
    d) # debug build
        BUILD_TYPE=debug
        CFLAGS="-g -O0"
        ;;
    s) # Fetch source only
        echo "fetcjing source"
        BUILD_TRILINOS=0
        BUILD_XYCE=0
        unset INSTALL_XYCE
        ;;
    t) # Build Trilinos only
        BUILD_TRILINOS=1
        BUILD_XYCE=0
        unset INSTALL_XYCE
        ;;
    x) # Build Xyce only
        BUILD_TRILINOS=0
        BUILD_XYCE=1
        unset INSTALL_XYCE
        ;;
    i) # Install
        BUILD_TRILINOS=0
        BUILD_XYCE=0
        INSTALL_XYCE=${OPTARG}
        ;;
    \?) # Invalid option
        echo "Error: Invalid option"
        echo
        Help
        exit;;
  esac
done

shift  $((OPTIND-1))
CONFIGURE_OPTS="$CONFIGURE_OPTS $@"
TRILINOS_CONFIGURE_OPTS=""

case "$OSTYPE" in
  linux*)   OS="Linux" ;;
  darwin*)  OS="Darwin" ;;
  win*)     OS="Windows" ;;
  msys*)    OS="Windows_MSYS2" ;;
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

    SUITESPARSE_INC=/usr/include/suitesparse
    LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
    INCLUDE_PATH=/usr/include
    export SUITESPARSE_INC LIBRARY_PATH INCLUDE_PATH

  else
    echo "Unknown Linux distro - please figure out the packages to install and submit an issue!"
    exit 1
  fi
elif [[ "$OS" == "Darwin" ]]; then
  if [[ -z "$HOMEBREW_PREFIX" ]]; then
    echo "This currently only works for Homebrew. Feel free to submut a PR!"
    exit 1
  fi

  HOMEBREW_NO_AUTO_UPDATE=1 brew install openblas cmake lapack bison flex fftw suitesparse autogen open-mpi
  PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/lapack/lib/pkgconfig"
  PATH="$HOMEBREW_PREFIX/opt/bison/bin:$HOMEBREW_PREFIX/opt/flex/bin:$PATH"
  LDFLAGS="-L$HOMEBREW_PREFIX/opt/bison/lib -L$HOMEBREW_PREFIX/opt/flex/lib"
  CPPFLAGS="-I$HOMEBREW_PREFIX/opt/bison/include -I$HOMEBREW_PREFIX/opt/flex/include"
  LDFLAGS="-L$HOMEBREW_PREFIX/opt/libomp/lib -L$HOMEBREW_PREFIX/lib $LDFLAGS"
  CPPFLAGS="-I/$HOMEBREW_PREFIX/opt/libomp/include -I$HOMEBREW_PREFIX/include/suitesparse -I$HOMEBREW_PREFIX/include $CPPFLAGS"
  LEX=$HOMEBREW_PREFIX/opt/flex/bin/flex
  BISON=$HOMEBREW_PREFIX/opt/bison/bin/bison
  export PKG_CONFIG_PATH PATH LDFLAGS CPPFLAGS LEX BISON

  SUITESPARSE_INC=$HOMEBREW_PREFIX/include/suitesparse
  LIBRARY_PATH=$HOMEBREW_PREFIX/lib
  INCLUDE_PATH=$HOMEBREW_PREFIX/include
  export SUITESPARSE_INC LIBRARY_PATH INCLUDE_PATH
elif [[ "$OS" == "Windows_MSYS2" || "$OS" == "Cygwin" ]]; then
  GCC_VERSION=$(gcc --version)
  if [ -z $? ]; then
    echo "No gcc found"
    exit 1
  fi
  # check we have pacman
  pacman --version

  ./scripts/windows-install.sh

  TRILINOS_CONFIGURE_OPTS="-DBLAS_LIBRARY_NAMES=openblas_64 -DBLAS_INCLUDE_DIRS=/ucrt64/include/openblas64 -DLAPACK_LIBRARY_NAMES=lapack64 -D "
  SUITESPARSE_INC=/ucrt64/include/suitesparse
  LIBRARY_PATH=/ucrt64/lib/x86_64-linux-gnu
  INCLUDE_PATH=/ucrt64/include
  export SUITESPARSE_INC LIBRARY_PATH INCLUDE_PATH

else
  echo "Unknown environment"
fi

if [ -n "$FETCH_SOURCE" ]; then
  ./scripts/fetch-source.sh
fi

# Set up environment variables
export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CFLAGS -fPIC -std=c++17 -Wno-unused-command-line-argument"

CCACHE=$(which ccache >/dev/null || echo '')
# Use MPI compilers
if [ -z "$CCACHE" ]; then
  export CXX=mpicxx
  export CC=mpicc
  export F77=mpif77
else
  export CXX="$CCACHE mpicxx"
  export CC="$CCACGE mpicc"
  export F77=mpif77
fi

export ARCHDIR="$ROOT/_build/libs"

if [ -n "$INSTALL_XYCE" ]; then
  export INSTALL_PATH="$INSTALL_XYCE"
else
  export INSTALL_PATH="$ROOT/__install"
fi

if [ -n "$BUILD_TRILINOS" ]; then
  ./scripts/build-trilinos.sh $TRILINOS_CONFIGURE_OPTS
fi


if [ -n "$BUILD_XYCE" ]; then
  ./scripts/build-xyce.sh $CONFIGURE_OPTS
fi

if [ -n "$INSTALL_XYCE" ]; then
  export INSTALL_PATH="$INSTALL_XYCE"
  ./scripts/install-xyce.sh
fi
