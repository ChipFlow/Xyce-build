#!/bin/bash

CloneOrUpdate()
{
  repo=$1
  if [ ! -d $repo ]; then
    git clone --depth=1 https://github.com/Xyce/Xyce $repo
  else
    git -C $repo remote set-url origin  https://github.com/Xyce/Xyce
    git -C $repo checkout master
    git -C $repo pull --depth=1
    git -C $repo prune --expire now
    git -C $repo repack -a -d
  fi
}

mkdir -p _source
CloneOrUpdate $ROOT/_source/xyce
CloneOrUpdate $ROOT/_source/trilinos


