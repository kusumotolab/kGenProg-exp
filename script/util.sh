#!/bin/bash

base=/opt/apr-data

gradle_repo=$base/.gradle
m2_repo=$base/.m2

# kgp
kgp_base=$base/kgp
kgp_bin_from=$kgp_base/build/libs/kGenProg.jar
kgp_bin=$base/bin/kgp.jar
kgp_ver=master #exp-for-journal # 2018/11

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

# to share m2 repository
export MAVEN_OPTS="-Dmaven.repo.local=$m2_repo"
export GRADLE_USER_HOME="$gradle_repo"
alias cp='cp -f'

################################################################################
build_kgp() {
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


################################################################################
build_astor() {
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


################################################################################
build_d4j() {
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
build_all() {
    build_kgp
    build_astor
    build_d4j
}

################################################################################
checkout_math() {
    for i in $(seq $math_id_from $math_id_to); do
	_checkout Math $i
	_patch_surefire Math $i
	_build_math Math $i
    done
}

_checkout() {
    _target=$1
    _id=$2
    
    _target_l=$(echo $_target | tr '[:upper:]' '[:lower:]')
    _id_z=$(printf %03d $_id)
    _out=$example/$_target_l$_id_z

    mkdir -p $example
    $d4j_bin checkout -p $_target -v $_id"b" -w $_out
}

# https://issues.apache.org/jira/browse/SUREFIRE-1588
# https://stackoverflow.com/questions/53010200/maven-surefire-could-not-find-forkedbooter-class?noredirect=1&lq=1
_patch_surefire() {
    _target=$1
    _id=$2

    _target_l=$(echo $_target | tr '[:upper:]' '[:lower:]')
    _id_z=$(printf %03d $_id)
    _out=$example/$_target_l$_id_z
    
    cat $_out/pom.xml \
	| tr '\n' '\f' \
	| sed -e 's|\(<artifactId>maven-surefire-plugin</artifactId>\f \+<configuration>\)\(\f \+<includes>\)|\1\f<useSystemClassLoader>false</useSystemClassLoader> <!-- inserted for apr -->\2|' \
	| tr '\f' '\n' \
	| tee $pom 1>/dev/null
}

_build_math() {
    _target=$1
    _id=$2

    _target_l=$(echo $_target | tr '[:upper:]' '[:lower:]')
    _id_z=$(printf %03d $_id)
    _out=$example/$_target_l$_id_z
    
    mvn -f $_out/pom.xml compile test-compile -DskipTests
}

################################################################################
_run_kgp() {
    _target=$1
    _id=$2
    _id_z=$(printf %03d $_id)
    
    mkdir -p $out
    (
	cd $example/$_target$_id_z
	time java -jar $kgp_bin \
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
	
    ) 2>&1 | tee $out/kgp-$_target$_id_z.result
}


_get_d4j_param() {
    _key=$1
    echo $(cat defects4j.build.properties \
	| grep $_key \
	| sed "s/$_key=\(.\+\)/\1/" \
	| sed "s/::.\+//"
	)
}
