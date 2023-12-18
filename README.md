# ⚡️ Turbo Full Nodes

The goal of this project is to swiftly create fully synchronized full nodes within a matter of minutes - let's call them ⚡️ Turbo Full Nodes. Currently, obtaining a synchronized full node can be a time-consuming process, often taking hours or even days for engineers. It is a pervasive challenge experienced by the entire Ethereum community and it underscores a pressing need for the development of tools and solutions to alleviate this limitation. At Polygon Labs, we aim to fix that.

To achieve this we utilize periodic snapshots to establish consistent snapshots of a full node's data. The primary full node is tasked with keeping this data synchronized with the tip of the chain. ⚡️ Turbo Full Nodes are generated using the most recent snapshot from the primary full node, ensuring the initialization of the node is either in-sync or, in the worst-case scenario, out of sync only since the last snapshot. Thanks to the frequent snapshots taken at short intervals (every ten minutes or hour), the node synchronizes rapidly and becomes operational within a few minutes.

## 🛠️ Proof of Concept

To validate the feasibility and efficiency of ⚡️ Turbo Full Nodes, we will conduct a small Proof of Concept centered around creating and initializing stateful programs rapidly. In this experiment, we will:

1. **Full Node Simulation**: Simulate the behavior of a full node by developing a simple [program](./script.sh) that appends data to a file at a very fast pace. We can control how frequently and how much data we write to the file to simulate different network behaviors.

2. **Snapshot Mechanism**: Take periodic snapshots to capture the state of the program's data at short intervals.

3. **Instance Initialization**: Start new programs using the latest snapshots, ensuring swift initialization either in sync or with minimal divergence from the last snapshot.

We would monitor the time it takes to create a new synced instance given different parameters such as the frequency and size of snapshots. We aim to be able to spin up new instances within the five-minute limit.
