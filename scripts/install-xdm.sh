#!/bin/bash
set -e
set -o pipefail

echo "Installing XDMe..."
${MAKE} -C $BUILDDIR/XDM install 2>&1 | tee $BUILDDIR/install-XDM.log

echo "Build completed successfully!"
echo "Xyce installed to: $INSTALL_PATH"

