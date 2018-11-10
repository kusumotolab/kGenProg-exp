#!/bin/bash

# kgp
base=kgp
bin_from=$base/build/libs/kGenProg.jar
bin_to=bin/kgp.jar
ver=exp-for-journal # 2018/11

################################################################################
git clone 'https://github.com/kusumotolab/kGenProg.git' $base
git -C $base checkout -f $ver

gradle -p $base assemble

mkdir -p $(dirname $bin_to)
cp $bin_from $bin_to
