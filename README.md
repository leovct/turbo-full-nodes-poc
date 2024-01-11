# ⚡️ Turbo Full Nodes

## Table of Contents

- [Introduction](#introduction)
- [Proof of Concept](#proof-of-concept)
    - [Set Up](#set-up)
    - [Benchmark](#benchmark)

## Introduction

The goal of this project is to swiftly create fully synchronized full nodes within a matter of minutes - let us call them ⚡️ Turbo Full Nodes. Currently, obtaining a synchronized full node can be a time-consuming process, often taking hours or even days for engineers. It is a pervasive challenge experienced by the entire Ethereum community and it underscores a pressing need for the development of tools and solutions to alleviate this limitation. At Polygon Labs, we aim to fix that.

To achieve this we utilize periodic snapshots to establish consistent snapshots of a full node's data. The primary full node is tasked with keeping this data synchronized with the tip of the chain. ⚡️ Turbo Full Nodes are generated using the most recent snapshot from the primary full node, ensuring the initialization of the node is either in-sync or, in the worst-case scenario, out of sync only since the last snapshot. Thanks to the frequent snapshots taken at short intervals (every ten minutes or hour), the node synchronizes rapidly and becomes operational within a few minutes.

## Proof of Concept

To validate the feasibility and efficiency of ⚡️ Turbo Full Nodes, we will conduct a small Proof of Concept centered around creating and initializing stateful programs rapidly. In this experiment, we will:

1. **Full Node Simulation**: Simulate the behavior of a full node by developing a simple [program](./script.sh) that appends data to a file at a very fast pace. We can control how frequently and how much data we write to the file to simulate different network behaviors.

2. **Snapshot Mechanism**: Take periodic snapshots to capture the state of the program's data at short intervals.

3. **Instance Initialization**: Start new programs using the latest snapshots, ensuring swift initialization either in sync or with minimal divergence from the last snapshot.

We would monitor the time it takes to create a new synced instance given different parameters such as the frequency and size of snapshots. We aim to be able to spin up new instances within the five-minute limit.

### Set up

Let us set up a VM, running on Ubuntu, with a primary volume of 100Gb and a secondary volume of 200Gb.

#### Format / Mount a device

To work with btrfs, you need to create a partition table and allocate at least one partition for btrfs. Without the partition table, other tools and operating systems may mishandle the disk, leading to potential data loss.

Here is how you can view partitions on your file system using `parted`:

```bash
$ sudo parted -l
Model: Xen Virtual Block Device (xvd)
Disk /dev/xvda: 8590MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
14      1049kB  5243kB  4194kB                     bios_grub
15      5243kB  116MB   111MB   fat32              boot, esp
 1      116MB   8590MB  8474MB  ext4

Error: /dev/xvdb: unrecognised disk label
Model: Xen Virtual Block Device (xvd)
Disk /dev/xvdb: 107GB
Sector size (logical/physical): 512B/512B
Partition Table: unknown
Disk Flags:
```

To create a partition table on a specific disk (here `/dev/xvdb`), follow these steps:

```bash
$ sudo parted /dev/xvdb
GNU Parted 3.4
Using /dev/xvdb
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) mklabel gpt
(parted) mkpart my-btrfs btrfs 4MiB 100%
(parted) print
Model: Xen Virtual Block Device (xvd)
Disk /dev/xvdb: 107GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags:

Number  Start   End    Size   File system  Name      Flags
 1      4194kB  107GB  107GB  btrfs        my-btrfs
```

Next, format the `btrfs` partition:

```bash
$ sudo mkfs.btrfs /dev/xvdb -f
btrfs-progs v5.16.2
See <http://btrfs.wiki.kernel.org> for more information.

NOTE: several default settings have changed in version 5.15, please make sure
      this does not affect your deployments:
      - DUP for metadata (-m dup)
      - enabled no-holes (-O no-holes)
      - enabled free-space-tree (-R free-space-tree)

Label:              (null)
UUID:               cb8034cf-39bf-4f8d-b4e2-53adae86ea3b
Node size:          16384
Sector size:        4096
Filesystem size:    100.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP               1.00GiB
  System:           DUP               8.00MiB
SSD detected:       yes
Zoned device:       no
Incompat features:  extref, skinny-metadata, no-holes
Runtime features:   free-space-tree
Checksum:           crc32c
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1   100.00GiB  /dev/xvdb
```

Verify if the formatting was successful:

```bash
$ sudo btrfs filesystem show /dev/xvdb
Label: none  uuid: cb8034cf-39bf-4f8d-b4e2-53adae86ea3b
	Total devices 1 FS bytes used 192.00KiB
	devid    1 size 100.00GiB used 2.02GiB path /dev/xvdb
```

Finally, mount the `btrfs` file system:

```bash
$ sudo mkdir /data
$ sudo mount /dev/xvdb /data
$ mount | grep btrfs
/dev/xvdb on /data type btrfs (rw,relatime,ssd,space_cache=v2,subvolid=5,subvol=/)
```

#### Create a snapshot

Let's delve into the realm of btrfs snapshots, starting with an introduction to subvolumes. **Subvolumes** provide distinct file and directory structures within the filesystem, allowing for flexible organisation of data. **Snapshots**, on the other hand, offer a point-in-time copy of a subvolume, facilitating tasks like versioning, deduplication, or creating a stable reference point for backups.

This combination of subvolumes and snapshots offers a versatile and efficient approach to managing filesystem content. Despite being a type of subvolume, a snapshot functions independently, **ensuring that any modifications made within the snapshot won't impact the original subvolume**.

To create a subvolume, follow these steps:

```bash
$ sudo mkdir /data/volumes /data/snapshots
$ sudo btrfs subvolume create /data/volumes/test
Create subvolume '/data/volumes/test'
```

After adding data to the volume, when you wish to capture a snapshot, use the following command:

```bash
$ btrfs subvolume snapshot <volume_path> <snapshot_path>
```

This creates a snapshot reflecting the content of the original subvolume at the time of the snapshot's creation.

If you want the snapshot to be read-only, you can use the `-r` flag.

```bash
$ btrfs subvolume snapshot -r <volume_path> <snapshot_path>
```

#### Simulate the behaviour of an Ethereum node

Start the following processes:

- `Writer`: simulate the behavior of a full node by appending data to a file at regular intervals.
- `Snapshoter`: takes periodic snapshots of a `btrfs` volume.

```bash
$ cd /home/ubuntu \
    && git clone https://github.com/leovct/turbo-full-nodes-poc.git \
    && cd turbo-full-nodes-poc \
    && sudo cp writer.service snapshoter.service /etc/systemd/system/ \
    && sudo systemctl daemon-reload \
    && sudo systemctl restart writer snapshoter \
    && sudo systemctl status writer snapshoter
```

Then transfer the snapshot to another host and measure the time it takes to transfer voluminous states (100M, 500M, 1G, 100G, 500G, 1T, 2T).

#### Handy commands

##### Scripts

- Check the status of the scripts: `sudo systemctl status writer snapshoter`
- Restart the scripts: `sudo systemctl restart writer snapshoter`
- Stop the scripts: `sudo systemctl stop writer snapshoter`
- Get the logs of any script: `journalctl -xfu snapshoter`

##### Data

- Check the size of the data volume: `df -h /data`
- Clean up: `sudo rm /data/volumes/test/bytes`
- Create a file of 100Mb: `sudo dd if=/dev/zero of=test.img bs=1024 count=0 seek=$[1024*100]`
- Create a file of 100GB: `sudo dd if=/dev/zero of=1g.img bs=1 count=0 seek=1G`
- Get the size of files (in human readable format): `ls -lh .`

##### Snapshots

- Delete a snapshot: `btrfs subvolume delete <name>`
- Delete all the snapshots: `ls /data/snapshots/ | xargs -I{} sudo btrfs subvolume delete /data/snapshots/{}`

### Benchmark

The challenge of this approach is to send the initial bulk of data (the initial snapshot) because it is very voluminous. In the case of PoS, it might be around 1Tb to 2Tb. Let's say if we want to spin up a new fullnode in a matter of seconds or minutes, we should make sure this process is fast.

That's why I wrote a [script](benchmark.sh) to compare the time it takes to send voluminous snapshots to a remote host using `btrfs send` and `btrfs receive`. Here are some of the initial results.

| Snapshot Size | Time it takes to send the snapshot to a remote host |
| ---- | ---- |
| 10M | 0.321s |
| 100M | 1.000s |
| 500M | TBD |
| 1G | 8.787s |
| 10G | TBD |
| 100G | TBD |
| 500G | TBD |
| 1T | TBD |
| 2T | TBD |
