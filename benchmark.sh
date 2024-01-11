#!/bin/bash
volume=/data/volumes/test2
snapshots=/data/snapshots
remote_host=$1 # ubuntu@<ip-remote-host>
sizes=("10M" "100M" "1G" "10G" "100G" "500G" "1T" "2T")

# Clean up
sudo rm $volume/*
sudo btrfs subvolume delete $snapshots/snapshot_test_*
ssh $remote_host "sudo btrfs subvolume delete /data/snapshot_test*"

# Benchmark
for size in "${sizes[@]}"; do
    # Convert size to megabytes.
    sizeValue=$(echo $size | sed 's/[^0-9]*//g')
    sizeUnit=$(echo $size | sed 's/[0-9]*//g')
    case $sizeUnit in
        M|m) sizeMega=$((sizeValue * 1024)) ;;
        G|g) sizeMega=$((sizeValue * 1024 * 1024)) ;;
        T|t) sizeMega=$((sizeValue * 1024 * 1024 * 1024)) ;;
        *) echo "Invalid size unit: $sizeUnit"; exit 1 ;;
    esac
    echo; echo "[Test: ${size} snapshot]"

    echo "> Creating file"
    start_time=$(date +%s%N)
    sudo head -c $size < /dev/urandom | sudo tee $volume/random_$size.img > /dev/null
    end_time=$(date +%s%N)
    elapsed_time=$(( ($end_time - $start_time) / 1000000))
    echo "Elapsed Time: $elapsed_time milliseconds"

    echo "> Creating snapshot"
    start_time=$(date +%s%N)
    sudo btrfs subvolume snapshot -r $volume $snapshots/snapshot_test_$size
    end_time=$(date +%s%N)
    elapsed_time=$(( ($end_time - $start_time) / 1000000))
    echo "Elapsed Time: $elapsed_time milliseconds"

    echo "> Check the size of the snapshot (real/apparent)"
    du -h $snapshots/snapshot_test_$size/*
    du --apparent-size -h $snapshots/snapshot_test_$size/*

    echo "> Sending snapshot to the remote host"
    start_time=$(date +%s%N)
    sudo btrfs send /data/snapshots/snapshot_test_$size | pv -s $sizeMega"M" -c -e -r | ssh $remote_host "sudo btrfs receive /data"
    end_time=$(date +%s%N)
    elapsed_time=$(( ($end_time - $start_time) / 1000000))
    echo "Elapsed Time: $elapsed_time milliseconds"

    echo "> Check the size of the snapshot on the remote host (real/apparent)"
    ssh $remote_host "du -h /data/snapshot_test_$size"/*
    ssh $remote_host "du --apparent-size -h /data/snapshot_test_$size"/*

    echo "> Cleaning up volume"
    sudo rm $volume/random_$size.img
done
