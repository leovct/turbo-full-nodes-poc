#!/bin/bash

# Bash script to simulate the behavior of appending data to a file at regular intervals.
# For example, such program would write 1024 bytes each second to file.txt.
# $ bash script.sh bytes 1024 1

# The path of the file to which data will be appended.
data_file_path="$1"

# The size of the data, in bytes, to write in each iteration.
write_size="$2"

# The time interval, in seconds, between each write opeation in seconds.
write_interval="$3"

# Check if the correct number of arguments is provided.
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <file> <write_size_bytes> <write_interval_seconds>"
  exit 1
fi

# Store data to file given the parameters.
while true; do
  data=$(od -An -N $write_size /dev/urandom | tr -d ' \n')
  echo "$data" >> "$data_file_path"
  sleep "$write_interval"
done
