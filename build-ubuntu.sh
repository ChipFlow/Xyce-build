#!/bin/bash -xv
set -e

ROOT=$(pwd)
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

./scripts/install-ubuntu.sh

# Verify CMake version
echo "CMake version: $(cmake --version | head -1)"

echo "FETCH_SOURCE: $FETCH_SOURCE, BUILD_TRILINOS=$BUILD_TRILINOS BUILD_XYCE=$BUILD_XYCE"

if [ -n "$FETCH_SOURCE" ]; then
  ./scripts/fetch-sources.sh
fi

# Set up environment variables
export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export CXXFLAGS="$CXXFLAGS -std=c++17"

# Use MPI compilers
export CXX=mpicxx
export CC=mpicc
export F77=mpif77

export ARCHDIR=$ROOT/_build/libs

if [ -n "$BUILD_TRILINOS" ]; then
  ./scripts/build-trilinos.sh
fi


if [ -n "$BUILD_XYCE" ]; then
  ./scripts/build-xyce.sh
fi

if [ -n "$INSTALL_XYCE"]; then
  ./scripts/install-xyce.sh
fi
