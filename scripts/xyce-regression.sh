#!/bin/bash
set -e
set -o pipefail
set -x


BUILD_DIR="$ROOT/$BUILDDIR"
mkdir -p $BUILD_DIR

XYCE_BINARY="$BUILD_DIR/Xyce/src/Xyce"
XYCE_REGRESSION=$ROOT/_source/Xyce_Regression

NCPUS="${NCPUS:-$(nproc)}"
REGRESSION_MAX_CPUS="${REGRESSION_MAX_CPUS:-$NCPUS}"
if [[ $NCPUS -gt $REGRESSION_MAX_CPUS ]]; then
  NCPUS=$REGRESSION_MAX_CPUS
fi

EXECSTRING="mpirun -np 2 $XYCE_BINARY"
eval `$XYCE_REGRESSION/TestScripts/suggestXyceTagList.sh "$XYCE_BINARY"`
$XYCE_REGRESSION/TestScripts/run_xyce_regressionMP \
--verbose \
--numproc=$NCPUS \
--xyce_test=$XYCE_REGRESSION \
--taglist="${TAGLIST}" \
--output=$BUILD_DIR/Xyce_Regression \
--resultfile=$BUILD_DIR/regression.results \
"${EXECSTRING}"
