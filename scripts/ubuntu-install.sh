#!/bin/bash
# Install dependencies using apt
if [ -z "$NO_UBUNTU_INSTALL" ]; then
  echo "Installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y $(cat $ROOT/data/ubuntu-packages.txt)
fi


