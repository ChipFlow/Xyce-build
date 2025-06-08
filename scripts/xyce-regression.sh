#!/bin/bash
set -e
set -o pipefail
set -x

BUILD_DIR="$ROOT/_build/"
XYCE_BINARY="$BUILD_DIR/xyce/src/Xyce"
XYCE_REGRESSION=$ROOT/_source/Xyce_Regression

NCPUS="${NCPUS:-$(nproc)}"

EXECSTRING="mpirun -np 2 $XYCE_BINARY"
eval `$XYCE_REGRESSION/TestScripts/suggestXyceTagList.sh "$XYCE_BINARY"`
$XYCE_REGRESSION/TestScripts/run_xyce_regressionMP \
--verbose \
--numproc=$NCPUS \
--xyce_test=$XYCE_REGRESSION \
--taglist="${TAGLIST}" \
--output=$BUILD_DIR/Xyce_Test \
--resultfile=$BUILD_DIR/regression.results \
"${EXECSTRING}"
