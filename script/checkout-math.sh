#!/bin/bash

# misc dirs
example=example

d4j_base=d4j
d4j=$d4j_base/framework/bin/defects4j

from=1
to=106

get() {
    target=$1
    id=$2
    target_l=$(echo $target | tr '[:upper:]' '[:lower:]')
    id_z=$(printf %03d $id)
    out=$example/$target_l$id_z

    mkdir -p $example
    $d4j checkout -p $target -v "$id"b -w $out
}

for i in $(seq $from $to); do
    get Math $i
done
