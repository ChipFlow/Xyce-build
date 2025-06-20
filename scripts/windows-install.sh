#!/bin/bash
# Install dependencies using apt
echo "Installing dependencies..."
pacman -S --needed \
  bison \
  flex \
  autoconf \
  automake \
  patch \
  pacboy

pacboy -S --needed \
  cmake \
  make \
  msmpi \
  openblas64 \
  lapack64 \
  fftw \
  suitesparse \
  msmpi \
  pkgconf \
  boost \
  boost-libs

curl -L -O https://github.com/microsoft/Microsoft-MPI/releases/download/v10.1.1/msmpisetup.exe
./msmpisetup.exe -unattend -force
export PATH="/c/Program Files/Microsoft MPI/Bin/$PATH"
