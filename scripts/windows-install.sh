#!/bin/bash
# Install dependencies using apt
echo "Installing dependencies..."
pacman -S --needed \
  pactoys \
  bison \
  flex

pacboy -S --needed \
  msmpi \
  cmake \
  make \
  openblas64 \
  lapack64 \
  fftw \
  suitesparse \
  pkgconf \
  boost \
  boost-libs \
  automake \
  autoconf 

curl -L -O https://github.com/microsoft/Microsoft-MPI/releases/download/v10.1.1/msmpisetup.exe
./msmpisetup.exe -unattend -force
export PATH="/c/Program Files/Microsoft MPI/Bin/$PATH"
