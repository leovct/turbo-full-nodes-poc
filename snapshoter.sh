#!/bin/bash

# Bash script that takes periodic snapshots of a btrfs volume.
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

# Take periodic (read-only) snapshots.
while true; do
  timestamp="$(date +'%m_%d_%Y-%H_%M_%S')"
  size="$(du -sb /data/volumes/test/ | awk '{print $1}')"
  sudo btrfs subvolume snapshot -r "$volume_path" "$snapshots_path/t$timestamp-s$size"
  echo "Snapshot taken at $timestamp"

  sleep $((snapshot_interval_minutes * 60))
done
