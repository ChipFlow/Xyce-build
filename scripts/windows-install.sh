#!/bin/bash
d# Install dependencies using apt
echo "Installing dependencies..."
pacman -S \
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
  mingw-w64-ucrt-x86_64-pkg-config

