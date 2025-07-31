#!/bin/bash

FAILURE=0

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S")
HOSTNAME=$(hostname)
TEST_START_TIME=$(date +%s.%N)

echo '<testsuite name="list_inputs_tests" timestamp="'"$TIMESTAMP"'" hostname="'"$HOSTNAME"'">' >> out/results.xml

# Export test files as a comma-separated string
export TEST_FILES="valid.json,invalid.json,empty.json,complex_expressions.json,special_chars.json,long_expression.json"

# Convert the comma-separated string into an array
IFS=',' read -r -a TEST_FILES_ARRAY <<< "$TEST_FILES"

# Count total tests
TOTAL_TESTS=${#TEST_FILES_ARRAY[@]}
FAILED_TESTS=0

# Loop through each test file
for TEST_FILE in "${TEST_FILES_ARRAY[@]}"; do
  echo "Running 'when list-inputs' for $TEST_FILE..."

  TEST_CASE_START_TIME=$(date +%s.%N)

  # Run the when binary command with the input and output file
  ./when list-inputs --input "test/files/inputs/$TEST_FILE" --output "/tmp/out.$TEST_FILE"

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
    echo "<testcase classname=\"list_inputs_tests\" name=\"list-inputs for $TEST_FILE\" time=\"$TEST_CASE_DURATION\">" >> out/results.xml
    echo "<failure message=\"Output does not match expected result\">$ERROR_MSG</failure>" >> out/results.xml
    echo "</testcase>" >> out/results.xml
  else
    echo "Success, result as expected."

    TEST_CASE_END_TIME=$(date +%s.%N)
    TEST_CASE_DURATION=$(echo "$TEST_CASE_END_TIME - $TEST_CASE_START_TIME" | bc)
    echo "TEST_CASE_DURATION: $TEST_CASE_DURATION"

    echo "<testcase classname=\"list_inputs_tests\" name=\"list-inputs for $TEST_FILE\" time=\"$TEST_CASE_DURATION\" />" >> out/results.xml
  fi
done

TEST_END_TIME=$(date +%s.%N)
TOTAL_DURATION=$(echo "$TEST_END_TIME - $TEST_START_TIME" | bc)

sed -i "s/<testsuite name=\"list_inputs_tests\" timestamp=\"$TIMESTAMP\" hostname=\"$HOSTNAME\">/<testsuite name=\"list_inputs_tests\" tests=\"$TOTAL_TESTS\" failures=\"$FAILED_TESTS\" errors=\"0\" skipped=\"0\" time=\"$TOTAL_DURATION\" timestamp=\"$TIMESTAMP\" hostname=\"$HOSTNAME\">/" out/results.xml
echo '</testsuite>' >> out/results.xml

exit $FAILURE
