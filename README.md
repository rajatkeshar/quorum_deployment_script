# Deployment-Scripts

### Installation
On the fresh machine to install Testnet

Clone the deployment-script repository, change the branch to ibft and run bootstrap.sh file
```
>git clone https://github.com/jpmorganchase/quorum.git
>cd quorum_deployment_scripts
>sudo ./bootstrap.sh
```
This script will install all prerequisites which includes:-
```
Tessera (0.6)
Go-lang (1.9.7)
Quorum Network
Dependencies packages (libdb-dev, libleveldb-dev, libleveldb-dev, libleveldb-dev, libleveldb-dev, solc, sysvbanner, software-properties-common, default-jdk, maven)
ipfs (optional)
```

### Create Consortium

To create a network with consensus type raft or ibft, there is `setup.sh` file. This can create n number nodes, initialize them and add them to network with consensus type selected.

#### Create New Network (RAFT)
Network Interactive Mode

Create a new node using raft consensus

```
>./setup.sh
>Select consensus type (raft/ibft/POA) : raft
>Please select an option:
 1) Create Network
 2) Join Network

option: 1
```

```
>./setup.sh
>Please enter node name: node1
>Please enter network id[Default:1101]:1101
>Is it permissioned node (y/n) [Default:n]:y
>Please enter IP Address of this node[Default:127.0.0.1]:
>Please enter RPC Port of this node[Default:22000]:
>Please enter Network Listening Port of this node[Default:22001]:
>Please enter Tessera Port of this node[Default:22002]:
>Please enter Tessera debug Port of this node[Default:22003]:
>Please enter Raft Port of this node[Default:22004]:
>Please enter WS Port of this node[Default:22005]:
```

#### Join New Node for existing network (RAFT)
Network Interactive Mode

To create a new node and add it to existing network which is using raft consensus.


```
>./setup.sh
>Select consensus type (raft/ibft/POA) : raft
>Please select an option:
 1) Create Network
 2) Join Network

option: 1
```

```
>./setup.sh
>Please enter node name: node1
>Please enter network id[Default:1101]:1101
>Is it permissioned node (y/n) [Default:n]:y
>Please enter IP Address of main node[Default:127.0.0.1]:
>Please enter Port of main node[Default:22000]:
>Please enter IP Address of this node[Default:127.0.0.1]:
>Please enter RPC Port of this node[Default:22000]:
>Please enter Network Listening Port of this node[Default:22001]:
>Please enter Tessera Port of this node[Default:22002]:
>Please enter Tessera debug Port of this node[Default:22003]:
>Please enter Raft Port of this node[Default:22004]:
>Please enter WS Port of this node[Default:22005]:
```

#### Create New Network (IBFT)

To create a new network for IBFT consensus. run `setup.sh` and select `2`. By default the nodes at network creation time will be validators.

Interactive Mode
```
>./setup.sh
>Is it admin node (y/n) [Default:n]:y
>If you want to create a network with raft enter 1. If you want to create network with ibft enter 2 : 2
>To Create a network enter 1. To join a network enter 2[Default:1]:1
>Nodes should be permissioned[Default:n]:
>Please enter network name:
>Please enter number of nodes to be created[Default:1]:
>Please enter current node Ip[Default:127.0.0.1]:
```

#### Add New Node for existing network (IBFT)

To create a new node and add it to existing network which is using IBFT consensus.

Interactive Mode
```
>./setup.sh
>Is it admin node (y/n) [Default:n]:n
>If you want to create a network with raft enter 1. If you want to create network with ibft enter 2 : 2
>To Create a network enter 1. To join a network enter 2[Default:1]:2
>Nodes should be permissioned[Default:n]:
>Please enter network name you want to join:
>Please enter number of nodes to be created[Default:1]
>Please enter current node Ip[Default:127.0.0.1]:
>Do you want to add it as validator (y/n)[Default:y]:
```

#### Stop the node

To stop the running node run `stop.sh` script
```
./stop.sh
```
