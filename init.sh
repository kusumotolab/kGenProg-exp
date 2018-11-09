#!/bin/bash
wd="$(cd "$(dirname $BASH_SOURCE)"; pwd -P)"

# misc dirs
out_dir=$wd/out
example=$wd/example

# kgp
kgp_base=$wd/kgp
kgp_bin=$kgp_base/build/libs/kGenProg.jar
kgp_ver=exp-for-journal # 2018/11

# astor
astor_base=$wd/astor
astor_bin=$astor_base/target/astor-0.0.2-SNAPSHOT-jar-with-dependencies.jar
astor_ver=61e33ecf2be00a5f03d06e49659ddfde7bcc1431  # 2018/11

# d4j
d4j_base=$wd/d4j
d4j_ver=8a2bb51a58dc805496c3ba6b9f1240ac61e37f76

################################################################################
build_kgp() {
    git clone 'https://github.com/kusumotolab/kGenProg.git' $kgp_base
    git -C $kgp_base checkout -f $kgp_ver

    gradle -p $kgp_base assemble
}

build_astor() {
    git clone 'https://github.com/SpoonLabs/astor.git' $astor_base
    git -C $astor_base checkout -f $astor_ver

    # patch for generating jar
    sed -i 's|<mainClass>fully.qualified.MainClass</mainClass>|<mainClass>fr.inria.main.evolution.AstorMain</mainClass>|' $astor_base/pom.xml

    mvn -f $astor_base/pom.xml compile install -DskipTests=true;
}

build_d4j() {
    git clone 'https://github.com/rjust/defects4j.git' $d4j_base
    git -C $d4j_base checkout -f $d4j_ver

    export PATH=$PATH:$d4j_base/framework/bin
    mkdir -p $example
}

get() {
    id=$1
    defects4j checkout -p Math -v "$id"b -w $example/math$id
}

################################################################################

build_kgp
build_astor
build_d4j
