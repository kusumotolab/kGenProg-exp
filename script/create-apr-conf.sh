#!/bin/bash

example=example

d4j_base=d4j
d4j=$d4j_base/framework/bin/defects4j

from=1
to=106

info() {
    target=$1
    id=$2
    target_u="$(tr '[:lower:]' '[:upper:]' <<< ${target:0:1})${target:1}"

    $d4j info -p $target_u -v $id
}

for i in $(seq $from $to); do
    info math $i
done
