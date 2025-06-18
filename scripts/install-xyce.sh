#!/bin/bash
set -e
set -o pipefail

echo "Installing Xyce..."
${MAKE} -C $BUILDDIR/Xyce install 2>&1 | tee $BUILDDIR/install-Xyce.log

echo "Build completed successfully!"
echo "Xyce installed to: $INSTALL_PATH"

