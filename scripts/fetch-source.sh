#!/bin/bash
mkdir -p _source
if [ ! -d _source/xyce ]; then
  git clone --depth=1 https://github.com/Xyce/Xyce $ROOT/_source/xyce
else
  git -C $ROOT/_source/xyce remote set-url origin  https://github.com/Xyce/Xyce
  git -C $ROOT/_source/xyce checkout master
  git -C $ROOT/_source/xyce pull --depth=1
fi

if [ ! -d _source/trilinos ]; then
  git clone --depth=1 https://github.com/robtaylor/Trilinos -b win-fix  $ROOT/_source/trilinos
else
  git -C $ROOT/_source/trilinos remote set-url origin https://github.com/robtaylor/Trilinos
  git -C $ROOT/_source/trilinos checkout master
  git -C $ROOT/_source/trilinos pull --depth=1
fi

