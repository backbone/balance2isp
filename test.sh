#!/bin/bash

EXE_PATH="`readlink -f $0`"
PRJ_PATH="${EXE_PATH%/*}"
for url in `cat $PRJ_PATH/sites.url`; do tracepath -m1 -n $url; done | grep 192.168
