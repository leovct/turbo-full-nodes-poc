#!/bin/bash

# Bash script that simulates the behavior of appending data to a file at regular intervals.
# For example, such program would write 1024 bytes each second to file.txt.
# $ bash writer.sh bytes 1024 1

# The path of the file to which data will be appended.
file_path="$1"

# The size of the data, in bytes, to write in each iteration.
write_size_bytes="$2"

# The time interval, in seconds, between each write opeation in seconds.
write_interval_seconds="$3"

# Check if the correct number of arguments is provided.
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <file_path> <write_size_bytes> <write_interval_seconds>"
  exit 1
fi

# Store data to file given the parameters.
while true; do
  data=$(od -An -N $write_size_bytes /dev/urandom | tr -d ' \n')
  echo "$data" >> "$file_path"

  sleep "$write_interval_seconds"
done
