#!/usr/bin/env bash
wd="$(cd "$(dirname $BASH_SOURCE)"; pwd -P)"

# user defined fields
kgp_ver=exp-for-journal # 2018/11/7
astor_ver=61e33ecf2be00a5f03d06e49659ddfde7bcc1431  # 2018/11

# miscs
kgp_base=$wd/kgp
astor_base=$wd/astor

kgp_bin=$kgp_base/build/libs/kGenProg.jar
astor_bin=$astor_base/target/astor-0.0.2-SNAPSHOT-jar-with-dependencies.jar

out_dir=$wd/out

################################################################################
build_kgp() {
    if [ ! -d $kgp_base ]; then
	git clone 'git@github.com:kusumotolab/kGenProg.git' $kgp_base
    else
	git -C $kgp_base fetch
    fi
    git -C $kgp_base checkout -f $kgp_ver
    
    git -C $kgp_base submodule init
    git -C $kgp_base submodule update
    
    gradle -p $kgp_base assemble
}

build_astor() {
    if [ ! -d $astor_base ]; then
	git clone 'https://github.com/SpoonLabs/astor.git' $astor_base
    else
	git -C $astor_base fetch
    fi
    git -C $astor_base checkout -f $astor_ver
    
    sed -i 's|<mainClass>fully.qualified.MainClass</mainClass>|<mainClass>fr.inria.main.evolution.AstorMain</mainClass>|' $astor_base/pom.xml
    mvn -f $astor_base/pom.xml compile install -DskipTests=true;
}

################################################################################
# $ run astor 70
run() {
    mode=$1
    target_id=$2
    target_pr=math
    target=$target_pr$target_id
    out=$out_dir/$mode-$target.out

    mkdir -p $out_dir

    if [ $mode = "kgp" ]; then
	target_dir=$kgp_base/example/real-bugs/Math$target_id
	exec=run_kgp

    elif [ $mode = "astor" ]; then
	target_dir=$astor_base/examples/math_$target_id
	exec=run_astor
    else
	return
    fi
    
    echo $target | tee $out
    (time $exec $target_dir $out) 2>&1 | tee -a $out
}

################################################################################
run_kgp() {
    target_dir=$1
    out=$2
    (
	cd $target_dir
	java -jar $kgp_bin
    ) # to temporarily change working dir.
}

################################################################################
run_astor() {
    target_dir=$1
    out=$2
    
    mvn -f $target_dir/pom.xml clean compile test
    java -jar $astor_bin \
	 -mode jgenprog \
	 -location $target_dir \
	 -scope package \
	 -failing org.apache.commons.math.analysis.solvers.BisectionSolverTest \
	 -srcjavafolder /src/main/java/ \
	 -srctestfolder /src/test/java/ \
	 -binjavafolder /target/classes \
	 -bintestfolder /target/test-classes \
	 -dependencies $astor_base/examples/libs/junit-4.4.jar \
	 -flthreshold 0.5 \
	 -seed 10 \
	 -maxtime 100 \
	 -maxgen 500 \
	 -stopfirst true \

#	 -autocompile 1 \
}
