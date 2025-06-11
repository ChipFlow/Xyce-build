#!/bin/bash
set -e
set -o pipefail

echo "Installing Xyce..."
make -C _build/Xyce install 2>&1 | tee _build/install-Xyce.log

echo "Build completed successfully!"
echo "Xyce installed to: $INSTALL_PATH"

