#!/bin/bash
mkdir -p _source
if [ ! -d _source/xyce ]; then
  git clone https://github.com/Xyce/Xyce _source/xyce
else
  git -C xyce pull
fi
if [ ! -d _source/trilinos ]; then
  git clone https://github.com/trilinos/Trilinos -b trilinos-release-14-4-0 _source/trilinos
fi

