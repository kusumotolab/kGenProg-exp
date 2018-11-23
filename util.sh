#!/bin/bash

base=/opt/apr-data

# repo caches
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

# common
example=$base/example
out=$base/out
tmp=$base/tmp

# to share repository caches
export MAVEN_OPTS="-Dmaven.repo.local=$m2_repo"
export GRADLE_USER_HOME="$gradle_repo"

# time command
export TIMEFORMAT=$'\nreal %3R\nuser %3U\nsys  %3S'

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
        _build $_target $i
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

    cp $_out/pom.xml $_out/pom.xml.orig

    cat $_out/pom.xml.orig \
        | tr '\n' '\f' \
        | sed -e 's|\(<artifactId>maven-surefire-plugin</artifactId>\f \+<configuration>\)\(\f \+<includes>\)|\1\f<useSystemClassLoader>false</useSystemClassLoader> <!-- inserted for apr -->\2|' \
        | tr '\f' '\n' \
        | tee $_out/pom.xml 1>/dev/null
}

_build() {
    _target=$1
    _id=$2

    _idz=$(printf %03d $_id)
    _out=$example/$_target$_idz

    mvn -f $_out/pom.xml compile test-compile -DskipTests
}

################################################################################
run() {
    _target=$1
    _id=$2

    # 引数がなければ環境変数から，あれば引数から
    if [[ -z $3 ]]; then
        _mode=$APR
    else
        _mode=$3
    fi

    # 引数がなければ環境変数から，あれば引数から
    if [[ -z $4 ]]; then
        _seed=$SEED
    else
        _seed=$4
    fi

    mkdir -p $out

    # 実行
    if [[ $_mode = "kgp" ]]; then
        _run_kgp $_target $_id $_seed

    elif [[ $_mode = "genp" ]]; then
        _run_astor $_target $_id $_seed jgenprog

    elif [[ $_mode = "kali" ]]; then
        _run_astor $_target $_id $_seed jkali

    fi
}

_run_kgp() {
    _target=$1
    _id=$2
    _seed=$3

    _idz=$(printf %03d $_id)
    _t=$example/$_target$_idz

    (time (
         date
         echo $_t

         cd $_t
         cmd=$(echo java -jar $kgp_bin \
                    -r ./ \
                    -s $(_get_d4j_param d4j.dir.src.classes) \
                    -t $(_get_d4j_param d4j.dir.src.tests) \
                    $(printf -- '-x %s ' $(_get_d4j_param d4j.tests.trigger)) \
                    --time-limit 600 \
                    --test-time-limit 3 \
                    --max-generation 10000 \
                    --headcount 5 \
                    --mutation-generating-count 10 \
                    --crossover-generating-count 0 \
                    --random-seed $_seed \
                    -o $tmp
            )
         echo $cmd
         timeout 720 $cmd

     )) 2>&1 | tee $out/kgp-$_target$_idz-$_seed.result

    # -v
    # --random-seed 123
    # --crossover-generating-count 10
}

_run_astor() {
    _target=$1
    _id=$2
    _seed=$3
    _mode=$4

    _idz=$(printf %03d $_id)
    _t=$example/$_target$_idz

    (time (
         date
         echo $_t

         cd $_t
         cmd=$(echo java -jar $astor_bin \
                    -mode $_mode \
                    -location $_t \
                    -scope package \
                    -failing       $(_get_d4j_param d4j.tests.trigger | paste -sd ':' -) \
                    -srcjavafolder $(_get_d4j_param d4j.dir.src.classes) \
                    -srctestfolder $(_get_d4j_param d4j.dir.src.tests) \
                    -binjavafolder /target/classes \
                    -bintestfolder /target/test-classes \
                    -dependencies $astor_base/examples/libs/junit-4.4.jar \
                    -maxtime 600 \
                    -maxgen 10000000 \
                    -seed $_seed \
                    -flthreshold 0.1 \
                    -stopfirst true

            )
         echo $cmd

         mvn clean compile test-compile
         timeout 720 $cmd

     )) 2>&1 | tee $out/astor-$_target$_idz-$_seed.result

    # -seed 10
    # -autocompile 1
    # -stopfirst true
    # -population 100
    # -flthreshold 0.0
}

_get_d4j_param() {
    _key=$1
    cat defects4j.build.properties \
        | grep $_key \
        | sed "s/$_key=\(.\+\)/\1/" \
        | sed 's/,/\n/g' \
        | sed "s/::.\+//" \
        | sort \
        | uniq

    #     -i echo '"{}"'

}
