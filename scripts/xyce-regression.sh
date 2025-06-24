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

echo
echo "Running Xyce regression suite. Using Binary $XYCE_BINARY with $XYCE_REGRESSION"
echo
echo "Testing $XYCE_BINARY"
$XYCE_BINARY || echo "$XYCE_BINARY failed"
echo "Testing mpiexec"
mpiexec -np 2 $XYCE_BINARY || echo "mpirun -np 2 $XYCE_BINARY failed"

EXECSTRING="mpiexec -np 2 $XYCE_BINARY"
eval `$XYCE_REGRESSION/TestScripts/suggestXyceTagList.sh "$XYCE_BINARY"`
$XYCE_REGRESSION/TestScripts/run_xyce_regressionMP \
--verbose \
--numproc=$NCPUS \
--xyce_test=$XYCE_REGRESSION \
--taglist="${TAGLIST}" \
--output=$BUILD_DIR/Xyce_Regression \
--resultfile=$BUILD_DIR/regression.results \
"${EXECSTRING}"
