#!/bin/bash
d# Install dependencies using apt
echo "Installing dependencies..."
pacman -S --needed \
  bison \
  flex \
  mingw-w64-ucrt-x86_64-cmake \
  mingw-w64-ucrt-x86_64-make \
  mingw-w64-ucrt-x86_64-msmpi \
  mingw-w64-ucrt-x86_64-openblas64 \
  mingw-w64-ucrt-x86_64-lapack64 \
  mingw-w64-ucrt-x86_64-fftw \
  mingw-w64-ucrt-x86_64-suitesparse \
  mingw-w64-ucrt-x86_64-msmpi \
  mingw-w64-ucrt-x86_64-pkgconf \
  mingw-w64-ucrt-x86_64-boost \
  mingw-w64-ucrt-x86_64-boost-libs

curl -L -O https://github.com/microsoft/Microsoft-MPI/releases/download/v10.1.1/msmpisetup.exe
./msmpisetup.exe -unattend -force
export PATH="/c/Program Files/Microsoft MPI/Bin/$PATH"
