#!/bin/bash

# Bash script that takes snapshots of a volume at regular intervals.
# For example, such program would takes snapshots of the volume test every hour.
# $ bash snapshoter.sh test 60 snapshots

# The path of the volume to snapshot.
volume_path="$1"

# The snapshot inerval, in minutes.
snapshot_interval_minutes="$2"

# The path of the snapshost.
snapshots_path="$3"

# Check if the correct number of arguments is provided.
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <volume_path> <snapshot_interval_seconds> <snapshots_path>"
  exit 1
fi

# Log parameters on startup.
echo "Starting snapshoter process"
echo "- volume_path: $volume_path"
echo "- snapshot_interval_minutes: $snapshot_interval_minutes"
echo "- snapshots_path: $snapshots_path"

# Take periodic snapshots.
while true; do
  timestamp="$(date +'%m_%d_%Y-%H_%M_%S')"
  sudo btrfs subvolume snapshot "$volume_path" "$snapshots_path/$timestamp"
  echo "Snapshot taken at $timestamp"

  sleep $((snapshot_interval_minutes * 60))
done
