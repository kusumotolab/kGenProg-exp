#!/bin/bash

# https://issues.apache.org/jira/browse/SUREFIRE-1588
# https://stackoverflow.com/questions/53010200/maven-surefire-could-not-find-forkedbooter-class?noredirect=1&lq=1

example=example

find $example -maxdepth 2 -name 'pom.xml' -type f | while read pom; do
    cat $pom \
	| tr '\n' '\f' \
	| sed -e 's|\(<artifactId>maven-surefire-plugin</artifactId>\f \+<configuration>\)\(\f \+<includes>\)|\1\f<useSystemClassLoader>false</useSystemClassLoader> <!-- inserted for apr -->\2|' \
	| tr '\f' '\n' \
	| tee $pom 1>/dev/null

done
