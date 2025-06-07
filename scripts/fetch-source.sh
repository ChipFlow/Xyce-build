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
CloneOrUpdate https://github.com/Xyce/Xyce master $ROOT/_source/xyce
CloneOrUpdate https://github.com/robtaylor/Trilinos win-fix $ROOT/_source/trilinos


