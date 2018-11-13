#!/bin/bash

# astor
base=astor
bin_from=$base/target/astor-0.0.2-SNAPSHOT-jar-with-dependencies.jar
bin_to=bin/astor.jar
ver=61e33ecf2be00a5f03d06e49659ddfde7bcc1431  # 2018/11

################################################################################
git clone 'https://github.com/SpoonLabs/astor.git' $base
git -C $base checkout -f $ver

# patch for generating jar

# specify main class
sed -i 's|<mainClass>fully.qualified.MainClass</mainClass>|<mainClass>fr.inria.main.evolution.AstorMain</mainClass>|' $base/pom.xml

# patch for bug in surefire classloader
sed -i 's|</reuseForks>|</reuseForks><useSystemClassLoader>false</useSystemClassLoader>|' $base/pom.xml

mvn -f $base/pom.xml install -DskipTests

mkdir -p $(dirname $bin_to)
cp $bin_from $bin_to
