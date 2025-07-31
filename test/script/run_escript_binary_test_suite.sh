#!/bin/bash

FAILURE=0

mkdir -p out

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")
HOSTNAME=$(hostname)
TEST_START_TIME=$(date +%s.%N)

echo '<?xml version="1.0" encoding="UTF-8"?>' > out/results.xml
echo '<testsuites>' >> out/results.xml

FAILURE=0

./test_list_inputs.sh
if [ $? -ne 0 ]; then
    FAILURE=1
fi

./test_reduce.sh
if [ $? -ne 0 ]; then
    FAILURE=1
fi

echo '</testsuites>' >> out/results.xml

exit $FAILURE
