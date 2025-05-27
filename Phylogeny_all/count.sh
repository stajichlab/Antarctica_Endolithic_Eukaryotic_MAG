#!/usr/bin/bash -l
CPU=24
pushd input
find . -type f -print0 |  xargs -0 -P $CPU -n 40 zgrep -c "^>" > ../compressed.txt
find . -type l -print0 |  xargs -0 -P $CPU -n 40 zgrep -c "^>" >> ../compressed.txt
popd

