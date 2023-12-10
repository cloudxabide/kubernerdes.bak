# README - myapp

This directory contains files (namespace, deployment, service) to deploy an app - and in this case happens to have Topology Aware Hints (TAH) enabled.

The point of these files which contain a (somewhat) "generic" variable is to use 'envsubst' to replace that placeholder with a name you decide.

export MYAPP_NAME="blah"
FILE=${MYAPP_NAME}.yaml
envsubst < ${FILE}.tmp > ${FILE}
grep $MYAPP_NAME $FILE
