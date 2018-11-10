#!/bin/bash

# d4j
base=d4j
ver=8a2bb51a58dc805496c3ba6b9f1240ac61e37f76
d4j=$base/framework/bin/defects4j

# libperl
apt-get install libdbi-perl

################################################################################
git clone 'https://github.com/rjust/defects4j.git' $base
git -C $base checkout -f $ver

$base/init.sh
