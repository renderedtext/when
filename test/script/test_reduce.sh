#!/bin/bash

FAILURE=0

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")
HOSTNAME=$(hostname)
TEST_START_TIME=$(date +%s.%N)

echo '<testsuite name="reduce_tests" timestamp="'"$TIMESTAMP"'" hostname="'"$HOSTNAME"'">' >> out/results.xml

export TEST_FILES="reduce.json,missing_input.json,complex_boolean.json,nested_parentheses.json,edge_values.json,partial_inputs.json,malformed_inputs.json"
IFS=',' read -r -a TEST_FILES_ARRAY <<< "$TEST_FILES"
TOTAL_TESTS=${#TEST_FILES_ARRAY[@]}
FAILED_TESTS=0

# Loop through each test file
for TEST_FILE in "${TEST_FILES_ARRAY[@]}"; do
  echo "Running 'when reduce' for $TEST_FILE..."

  # Run the when binary command with the input and output file
  ./when reduce --input "test/files/inputs/$TEST_FILE" --output "/tmp/out.$TEST_FILE"

  # Compare the output with the expected file
  if ! diff <(jq --sort-keys . "/tmp/out.$TEST_FILE") <(jq --sort-keys . "test/files/expected_result/$TEST_FILE") > /dev/null
  then
    echo "Error while running when binary for file $TEST_FILE."
    echo "Expected:"
    cat test/files/expected_result/$TEST_FILE
    echo -e "\nActual result:"
    cat /tmp/out.$TEST_FILE
    echo -e "\n"
    FAILURE=1
    FAILED_TESTS=$((FAILED_TESTS+1))

    TEST_CASE_END_TIME=$(date +%s.%N)
    TEST_CASE_DURATION=$(echo "$TEST_CASE_END_TIME - $TEST_CASE_START_TIME" | bc)
    echo "TEST_CASE_DURATION: $TEST_CASE_DURATION"

    ERROR_MSG=$(diff <(jq --sort-keys . "/tmp/out.$TEST_FILE") <(jq --sort-keys . "test/files/expected_result/$TEST_FILE") | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g')
    echo "<testcase classname=\"reduce_tests\" name=\"reduce for $TEST_FILE\" time=\"$TEST_CASE_DURATION\">" >> out/results.xml
    echo "<failure message=\"Output does not match expected result\">$ERROR_MSG</failure>" >> out/results.xml
    echo "</testcase>" >> out/results.xml
  else
    echo "Success, result as expected."

    TEST_CASE_END_TIME=$(date +%s.%N)
    TEST_CASE_DURATION=$(echo "$TEST_CASE_END_TIME - $TEST_CASE_START_TIME" | bc)
    echo "TEST_CASE_DURATION: $TEST_CASE_DURATION"

    echo "<testcase classname=\"reduce_tests\" name=\"reduce for $TEST_FILE\" time=\"$TEST_CASE_DURATION\" />" >> out/results.xml
  fi
done

TEST_END_TIME=$(date +%s.%N)
TOTAL_DURATION=$(echo "$TEST_END_TIME - $TEST_START_TIME" | bc)

 sed -i "s/<testsuite name=\"reduce_tests\" timestamp=\"$TIMESTAMP\" hostname=\"$HOSTNAME\">/<testsuite name=\"reduce_tests\" tests=\"$TOTAL_TESTS\" failures=\"$FAILED_TESTS\" errors=\"0\" skipped=\"0\" time=\"$TOTAL_DURATION\" timestamp=\"$TIMESTAMP\" hostname=\"$HOSTNAME\">/" out/results.xml
echo '</testsuite>' >> out/results.xml

exit $FAILURE
