#!/bin/bash

CloneOrUpdate()
{
  url=$1
  branch=$2
  repo=$3
  if [ ! -d $repo ]; then
    git clone --depth=1 $url -b $branch $repo
  else
    git -C $repo remote set-url origin $url
    git -C $repo fetch --depth=1
    git -C $repo checkout $branch
    git -C $repo prune --expire now
    git -C $repo repack -a -d
  fi
}

mkdir -p _source
CloneOrUpdate https://github.com/Xyce/Xyce master $ROOT/_source/Xyce

# https://github.com/Xyce/Xyce_Regression/issues/4
CloneOrUpdate https://github.com/robtaylor/Xyce_Regression cmake-370-windows $ROOT/_source/Xyce_Regression
# See https://github.com/Xyce/XDM/issues/11
CloneOrUpdate https://github.com/tvrusso/XDM fixsstream $ROOT/_source/XDM
# CloneOrUpdate https://github.com/tvrusso/XDM fixsstream $ROOT/_source/XDM

# Backport KokkosKernels: patch #2296 to 14.4.0
CloneOrUpdate https://github.com/robtaylor/Trilinos win-fix $ROOT/_source/trilinos


