# ⚡️ Turbo Full Nodes

The goal of this project is to swiftly create fully synchronized full nodes within a matter of minutes - let us call them ⚡️ Turbo Full Nodes. Currently, obtaining a synchronized full node can be a time-consuming process, often taking hours or even days for engineers. It is a pervasive challenge experienced by the entire Ethereum community and it underscores a pressing need for the development of tools and solutions to alleviate this limitation. At Polygon Labs, we aim to fix that.

To achieve this we utilize periodic snapshots to establish consistent snapshots of a full node's data. The primary full node is tasked with keeping this data synchronized with the tip of the chain. ⚡️ Turbo Full Nodes are generated using the most recent snapshot from the primary full node, ensuring the initialization of the node is either in-sync or, in the worst-case scenario, out of sync only since the last snapshot. Thanks to the frequent snapshots taken at short intervals (every ten minutes or hour), the node synchronizes rapidly and becomes operational within a few minutes.

## 🛠️ Proof of Concept

To validate the feasibility and efficiency of ⚡️ Turbo Full Nodes, we will conduct a small Proof of Concept centered around creating and initializing stateful programs rapidly. In this experiment, we will:

1. **Full Node Simulation**: Simulate the behavior of a full node by developing a simple [program](./script.sh) that appends data to a file at a very fast pace. We can control how frequently and how much data we write to the file to simulate different network behaviors.

2. **Snapshot Mechanism**: Take periodic snapshots to capture the state of the program's data at short intervals.

3. **Instance Initialization**: Start new programs using the latest snapshots, ensuring swift initialization either in sync or with minimal divergence from the last snapshot.

We would monitor the time it takes to create a new synced instance given different parameters such as the frequency and size of snapshots. We aim to be able to spin up new instances within the five-minute limit.

### Set up

Let us set up a VM, running on Ubuntu, with a primary volume of 100Gb and a secondary volume of 200Gb.

1. Create the `btrfs` file system.

Note: It may require `sudo` and the flag `-f` to force the formatting.

```bash
$ mkfs.btrfs /dev/xvdb
btrfs-progs v5.16.2
See http://btrfs.wiki.kernel.org for more information.

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

$ sudo btrfs filesystem show /dev/xvdb
Label: none  uuid: cb8034cf-39bf-4f8d-b4e2-53adae86ea3b
	Total devices 1 FS bytes used 192.00KiB
	devid    1 size 100.00GiB used 2.02GiB path /dev/xvdb
```

2. Mount the `btrfs` file system.

```bash
$ sudo mkdir /data \
    && sudo mount /dev/xvdb /data \
    && mount | grep btrfs
/dev/xvdb on /data type btrfs (rw,relatime,ssd,space_cache=v2,subvolid=5,subvol=/)
```

3. Create folders and the test volume.

```bash
$ mkdir volumes snapshots \
    && sudo btrfs subvolume create /data/volumes/test
Create subvolume '/data/volumes/test'
```

4. Start the processes.

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
5. Transfer the snapshot to another host.

6. Measure the time it takes to transfer voluminous states.

- 500MB
- 1GB
- 1,5GB
- 2GB

### Handy commands

#### Scripts

- Check the status of the scripts: `sudo systemctl status writer snapshoter`
- Restart the scripts: `sudo systemctl restart writer snapshoter`
- Stop the scripts: `sudo systemctl stop writer snapshoter`
- Get the logs of any script: `journalctl -xfu snapshoter`

#### Data

- Check the size of the data volume: `df -h /data`
- Clean up: `sudo rm /data/volumes/test/bytes`
- Create a file of 100Mb: `sudo dd if=/dev/zero of=test.img bs=1024 count=0 seek=$[1024*100]`
- Create a file of 100GB: `sudo dd if=/dev/zero of=1g.img bs=1 count=0 seek=1G`
- Get the size of files (in human readable format): `ls -lh .`

#### Snapshots

- Delete a snapshot: `btrfs subvolume delete <name>`
- Delete all the snapshots: `ls /data/snapshots/ | xargs -I{} sudo btrfs subvolume delete /data/snapshots/{}`
