#!/bin/bash

##################################################################################
#                                                                                #
# Quorum 2.2.1                                                                   #
#                                                                                #
##################################################################################

set -u
set -e

node=#NODE
validatorNode=''
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
NETWORK_ID=$(cat genesis.json | grep chainId | awk -F " " '{print $2}' | awk -F "," '{print $1}')

if [[ $NETWORK_ID -eq 1  || $NETWORK_ID -eq 2 || $NETWORK_ID -eq 3 || $NETWORK_ID -eq 4 || $NETWORK_ID -eq 8 || $NETWORK_ID -eq 42 || $NETWORK_ID -eq 77 || $NETWORK_ID -eq 99 || $NETWORK_ID -eq 7762959 || $NETWORK_ID -eq 61717561 ]];
then
    echo "  Quorum should not be run with a chainId of 1 (Ethereum mainnet)"
    echo "  Quorum should not be run with a chainId of 2 (Morden, the public Ethereum testnet, now Ethereum Classic testnet)"
    echo "  Quorum should not be run with a chainId of 3 (Ropsten, the public cross-client Ethereum testnet)"
    echo "  Quorum should not be run with a chainId of 4 (Rinkeby, the public Geth PoA testnet)"
    echo "  Quorum should not be run with a chainId of 8 (Ubiq, the public Gubiq main network with flux difficulty chain ID 8)"
    echo "  Quorum should not be run with a chainId of 42 (Kovan, the public Parity PoA testnet)"
    echo "  Quorum should not be run with a chainId of 77 (Sokol, the public POA Network testnet)"
    echo "  Quorum should not be run with a chainId of 99 (Core, the public POA Network main network)"
    echo "  Quorum should not be run with a chainId of 7762959 (Musicoin, the music blockchain)"
    echo "  Quorum should not be run with a chainId of 61717561 (Aquachain, ASIC resistant chain)"
    echo "  please set the chainId in the genensis.json to another value "
    echo "  1337 is the recommend ChainId for Geth private clients."
fi

mkdir -p logs

echo "[*] Starting Tessera nodes"
./tessera_start.sh

echo "[*] Starting node with ChainID and NetworkId of $NETWORK_ID"
set -v
if [[ -z "$validatorNode" ]];
then
    ARGS="--nodiscover --istanbul.blockperiod 5 --networkid $NETWORK_ID --syncmode full --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --emitcheckpoints"
else
    ARGS="--nodiscover --istanbul.blockperiod 5 --networkid $NETWORK_ID --syncmode full --mine --minerthreads 1 --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --emitcheckpoints"
fi

echo $ARGS

PRIVATE_CONFIG=node/tesseraConfig/tm.ipc nohup geth --datadir node $ARGS #STARTCMD --unlock 0 --password password.txt 2>>logs/${node}.log &
set +v

echo
echo "${node} configured. See '${node}/logs' for logs, and run e.g. 'geth attach ${node}/geth.ipc' to attach to the first Geth node."

exit 0
