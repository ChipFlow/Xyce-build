#!/bin/bash
set -e
set -o pipefail

echo "Installing Xyce..."
make -C _build/Xyce install 2>&1 | tee _build/Xyce-install.log

echo "Build completed successfully!"
echo "Xyce installed to: $INSTALL_PATH"

