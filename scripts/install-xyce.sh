#!/bin/bash
echo "Installing Xyce..."
make -C _build/xyce install 2>&1 | tee _build/xyce-install.log

echo "Build completed successfully!"
echo "Xyce installed to: $INSTALL_PATH"

