#!/bin/bash

for url in `cat sites.url`; do tracepath -m1 -n $url; done | grep 192.168
