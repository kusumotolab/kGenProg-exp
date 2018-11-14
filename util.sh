#!/bin/bash

base=/opt/apr-data

gradle_repo=$base/.gradle
m2_repo=$base/.m2

# kgp
kgp_base=$base/kgp
kgp_bin_from=$kgp_base/build/libs/kGenProg.jar
kgp_bin=$base/bin/kgp.jar
kgp_ver=exp-for-journal # 2018/11

# astor
astor_base=$base/astor
astor_bin_from=$astor_base/target/astor-0.0.2-SNAPSHOT-jar-with-dependencies.jar
astor_bin=$base/bin/astor.jar
astor_ver=61e33ecf2be00a5f03d06e49659ddfde7bcc1431  # 2018/11

# d4j
d4j_base=$base/d4j
d4j_ver=8a2bb51a58dc805496c3ba6b9f1240ac61e37f76
d4j_bin=$d4j_base/framework/bin/defects4j

# d4j math
math_id_from=1
math_id_to=106

# common
example=$base/example
out=$base/out
tmp=$base/tmp

# to share repository caches
export MAVEN_OPTS="-Dmaven.repo.local=$m2_repo"
export GRADLE_USER_HOME="$gradle_repo"

# avoid confirmation
alias cp='cp -f'


################################################################################
build() {
    mode=$1
    _build_$mode
}

_build_kgp() {
    if [ ! -d $kgp_base ]; then
	git clone 'https://github.com/kusumotolab/kGenProg.git' $kgp_base
    else
	:
	git -C $kgp_base pull
    fi
    git -C $kgp_base checkout -f $kgp_ver
    
    gradle -p $kgp_base assemble
    
    mkdir -p $(dirname $kgp_bin)
    cp $kgp_bin_from $kgp_bin
}


_build_astor() {
    if [ ! -d $astor_base ]; then
	git clone 'https://github.com/SpoonLabs/astor.git' $astor_base
    else
	:
	# git -C $astor_base pull
    fi
    git -C $astor_base checkout -f $astor_ver
    
    # patch for generating jar
    # specify main class
    sed -i 's|<mainClass>fully.qualified.MainClass</mainClass>|<mainClass>fr.inria.main.evolution.AstorMain</mainClass>|' $astor_base/pom.xml
    
    # patch for bug in surefire classloader
    sed -i 's|</reuseForks>|</reuseForks><useSystemClassLoader>false</useSystemClassLoader>|' $astor_base/pom.xml
    
    mvn -f $astor_base/pom.xml install -DskipTests
    
    mkdir -p $(dirname $astor_bin)
    cp $astor_bin_from $astor_bin
}


_build_d4j() {
    if [ ! -d $d4j_base ]; then
	git clone 'https://github.com/rjust/defects4j.git' $d4j_base
    else
	:
	# git -C $d4j_base pull
    fi
    git -C $d4j_base checkout -f $d4j_ver
    
    $d4j_base/init.sh
}


################################################################################
checkout() {
    _target=$1
    shift

    for i in ${@}; do
	_checkout $_target $i
	_patch_surefire $_target $i
	# _build_math Math $i
    done
}

_checkout() {
    _target=$1
    _id=$2
    
    _targetu=$(tr '[:lower:]' '[:upper:]' <<< ${_target:0:1})${_target:1}

    _idz=$(printf %03d $_id)
    _out=$example/$_target$_idz

    mkdir -p $example
    $d4j_bin checkout -p $_targetu -v $_id"b" -w $_out
}

# https://issues.apache.org/jira/browse/SUREFIRE-1588
# https://stackoverflow.com/questions/53010200/maven-surefire-could-not-find-forkedbooter-class?noredirect=1&lq=1
_patch_surefire() {
    _target=$1
    _id=$2

    _idz=$(printf %03d $_id)
    _out=$example/$_target$_idz


    echo $_out/pom.xml

    cat $_out/pom.xml \
	| tr '\n' '\f' \
	| sed -e 's|\(<artifactId>maven-surefire-plugin</artifactId>\f \+<configuration>\)\(\f \+<includes>\)|\1\f<useSystemClassLoader>false</useSystemClassLoader> <!-- inserted for apr -->\2|' \
	| tr '\f' '\n' \
	| tee $_out/pom.xml 1>/dev/null
}

_build_math() {
    _target=$1
    _id=$2

    _targetu=$(tr '[:lower:]' '[:upper:]' <<< ${_target:0:1})${_target:1}
    
    _idz=$(printf %03d $_id)
    _out=$example/$_target$_idz
    
    mvn -f $_out/pom.xml compile test-compile -DskipTests
}

################################################################################
run() {
    mode=$1
    
    mkdir -p $out
    
    _run_$mode $2 $3
}

_run_kgp() {
    _target=$1
    _id=$2
    _idz=$(printf %03d $_id)
    _t=$example/$_target$_idz
    
    time (
	cd $_t
	java -jar $kgp_bin \
	     -r ./ \
	     -s $(_get_d4j_param d4j.dir.src.classes) \
	     -t $(_get_d4j_param d4j.dir.src.tests) \
	     -x $(_get_d4j_param d4j.tests.trigger) \
	     --time-limit 60 \
	     --max-generation 1000 \
	     --test-time-limit 3 \
	     --headcount 10 \
	     --mutation-generating-count 100 \
	     --crossover-generating-count 0 \
	     -v \
	     -o $tmp
	
    ) 2>&1 | tee $out/kgp-$_target$_idz.result
}

_run_astor() {
    _target=$1
    _id=$2
    _idz=$(printf %03d $_id)
    _t=$example/$_target$_idz
    
    time (
	cd $_t
	mvn clean compile test
	java -jar $astor_bin \
	     -mode jgenprog \
	     -location $_t \
	     -scope package \
	     -failing       $(_get_d4j_param d4j.tests.trigger) \
	     -srcjavafolder $(_get_d4j_param d4j.dir.src.classes) \
	     -srctestfolder $(_get_d4j_param d4j.dir.src.tests) \
	     -binjavafolder /target/classes \
	     -bintestfolder /target/test-classes \
	     -dependencies $astor_base/examples/libs/junit-4.4.jar \
	     -flthreshold 0.5 \
	     -maxtime 100 \
	     -maxgen 500 \
	     -stopfirst true
	
    ) 2>&1 | tee $out/astor-$_target$_idz.result

#	 -seed 10 \
#	 -autocompile 1 \
}

_get_d4j_param() {
    _key=$1
    echo $(cat defects4j.build.properties \
	| grep $_key \
	| sed "s/$_key=\(.\+\)/\1/" \
	| sed "s/::.\+//"
	)
}

