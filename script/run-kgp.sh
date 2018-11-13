#!/bin/bash

example=example
out=$(realpath out)

d4j_base=d4j
d4j=$d4j_base/framework/bin/defects4j

kgp=$(realpath bin/kgp.jar)
astor=$(realpath bin/astor.jar)


get_param() {
    key=$1
    echo $(cat defects4j.build.properties \
	| grep $key \
	| sed "s/$key=\(.\+\)/\1/" \
	| sed "s/::.\+//"
	)
}

run() {
    target=$1
    id=$2
    id_z=$(printf %03d $id)
    
    mkdir -p $out
    (
	cd example/$target$id_z
	time java -jar $kgp \
	     -r ./ \
	     -s $(get_param d4j.dir.src.classes) \
	     -t $(get_param d4j.dir.src.tests) \
	     -x $(get_param d4j.tests.trigger) \
	     --time-limit 60 \
	     --max-generation 1000 \
	     --test-time-limit 3 \
	     --headcount 10 \
	     --mutation-generating-count 100 \
	     --crossover-generating-count 0 \
	     -v \
	     -o /tmp/ 
	
	
    ) 2>&1 | tee $out/kgp-$target$id_z.result
}

run $1 $2
# run_astor math 80
# run_astor math 85
# run_astor math 82
# run_astor math 83
# run_astor math 84
# run_astor math 85

# from=1
# to=106
# 
# for i in $(seq $from $to); do
#     run_astor math $i
# done
