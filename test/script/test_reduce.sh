#!/bin/bash

# Export test files as a comma-separated string
export TEST_FILES="reduce.json,missing_input.json"

# Convert the comma-separated string into an array
IFS=',' read -r -a TEST_FILES_ARRAY <<< "$TEST_FILES"

# Loop through each test file
for TEST_FILE in "${TEST_FILES_ARRAY[@]}"; do
  echo "Running 'when reduce' for $TEST_FILE..."  

  # Run the when binary command with the input and output file
  ./when reduce --input "test/files/inputs/$TEST_FILE" --output "/tmp/out.$TEST_FILE"

  # Compare the output with the expected file
  if ! diff "/tmp/out.$TEST_FILE" "test/files/expected_result/$TEST_FILE" > /dev/null 
  then
    echo "Error while running when binary for file $TEST_FILE."
    echo "Expected:"
    cat test/files/expected_result/$TEST_FILE
    echo -e "\nActual result:"
    cat /tmp/out.$TEST_FILE
    echo -e "\n"
  else
    echo "Success, result as expected."
  fi
done
