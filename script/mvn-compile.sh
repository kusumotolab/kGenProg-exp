#!/bin/bash

# astor
example=example

find $example -maxdepth 2 -name 'pom.xml' -type f | sort | while read pom; do
    mvn -f $pom compile test-compile -DskipTests
done
