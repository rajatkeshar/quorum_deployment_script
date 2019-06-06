#!/bin/bash

source variables
source raft/common.sh

tesseraJar=($TESSERA_JAR)

#function to generate keyPair for node
function generateKeyPair(){
    echo "[*] Generating keys for testnet account"
    # Generate the private and public keys
    openssl ecparam -name secp256k1 -genkey -noout | openssl ec -text -noout > Key
    # Extract the public key and remove the EC prefix 0x04
    cat Key | grep pub -A 5 | tail -n +2 | tr -d '\n[:space:]:' | sed 's/^04//' > pub
    # Extract the private key and remove the leading zero byte
    cat Key | grep priv -A 3 | tail -n +2 | tr -d '\n[:space:]:' | sed 's/^00//' > priv

	rm Key
}


#function to create start node script with --raft flag
function copyScripts(){
    cp ../../template/genesis_template_raft.json ../genesis.json
    sed -i "s|#CHAIN_ID#|${chainId}|g" ../genesis.json
    #sed -i "s|#mNodeAddress#|${acc_address}|g" ../genesis.json

    cp ../../template/tessera_start_template.sh ../tessera_start.sh
    cp ../../template/node_start_template_raft.sh ../node_start.sh

    echo ${password} > ../password.txt

    sed -i "s/#DPORT/${dPort}/g" ../tessera_start.sh
    sed -i "s/#NODE/'${mNode}'/g" ../tessera_start.sh
    #sed -i "s|#TESSERAJAR|'${tesseraJar}'|g" ../tessera_start.sh
    sed -i "s/#NODE/'${mNode}'/g" ../node_start.sh

    NETWORK_ID=$(cat ../genesis.json | grep chainId | awk -F " " '{print $2}' | awk -F "," '{print $1}')

    ARGS="--nodiscover --verbosity 5 --networkid $NETWORK_ID --raft --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,raft --emitcheckpoints"

    if [ "$nodeType" = "y" ];
    then
        #pattern="--permissioned --raftport ${raPort} --rpcport ${rPort} --port ${wPort}"
        pattern="--raftport ${raPort} --rpcport ${rPort} --port ${wPort}"
    else
        pattern="--raftport ${raPort} --rpcport ${rPort} --port ${wPort}"
    fi

    sed -i "s/#STARTCMD/${pattern}/g" ../node_start.sh
}

#function to gconfigure tessera
function generateTesseraConfig(){
    echo "[*] Generating tessera configuration"
    rm -rf tesseraConfig
    # Create logs and tessera config directory
    mkdir tesseraConfig
    #touch tesseraConfig/tessera-config.json
    mkdir -p qdata/logs
    # Generate keys
    echo "tessera path: " $tesseraJar
    echo "generate tessera config path: " $(pwd)

    printf "\n\n" | java -jar $tesseraJar -keygen -filename $(pwd)/tesseraConfig/
    echo "mNode: " $mNode
    echo "tPort: " $tPort
    ../../template/tessera_init_template.sh ${mNode} ${tPort}
}

#create setup
function createSetupConf(){
    echo "[*] Creating configuration file"

    echo 'NODENAME='${mNode} > node.conf
    echo 'WHISPER_PORT='${wPort} >> node.conf
    echo 'RAFT_PORT='${raPort} >> node.conf
    echo 'RPC_PORT='${rPort} >> node.conf
    echo 'TESSERA_PORT='${tPort} >> node.conf
    echo 'WS_PORT='${wsPort} >> node.conf
    echo 'CURRENT_IP='${pCurrentIp} >> node.conf
    echo 'REGISTERED=' >> node.conf
    echo 'MODE=ACTIVE' >> node.conf
    echo 'STATE=I' >> node.conf
}

#function to generate enode
function generateEnode(){
    bootnode -genkey nodekey
    nodekey=$(cat nodekey)
	bootnode -nodekey nodekey -verbosity 9 -addr :30310 2>enode.txt &
    pid=$!
	sleep 5
	kill -9 $pid
	wait $pid 2> /dev/null
	re="enode:.*@"
	enode=$(cat enode.txt)
    echo $enode
    if [[ $enode =~ $re ]];
    	then
        Enode=${BASH_REMATCH[0]};
    fi
    cp nodekey geth/.
    cp ../../template/static-nodes_template_raft.json static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#CURRENT_IP#|${pCurrentIp}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#W_PORT#|${wPort}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#raftPprt#|${raPort}|g"
    sed -i $PATTERN static-nodes.json

    #cp static-nodes.json permissioned-nodes.json
    rm enode.txt
    rm nodekey
}

#function to create node accout and append it into genesis.json file
function createAccount(){

    echo "[*] Creating account using generated keys and user password"
    # import the private key to geth and create a account
    current_pwd=$(pwd)

    acc_address="$(geth account import --datadir ${current_pwd} --password  <(echo $password) priv)"
    re="\{([^}]+)\}"

    if [[ $acc_address =~ $re ]];
    then
        acc_address="0x"${BASH_REMATCH[1]};
    fi
    mv keystore/* keystore/key
}

function cleanup(){
    rm -rf ${mNode}
    echo $mNode > .nodename
    mkdir -p ${mNode}/node/{keystore,geth,logs}
    mkdir -p ${mNode}/node/qdata
    cp variables $mNode
    cd ${mNode}/node/
}

# execute init script
function executeInit(){
    cd ..
    geth --datadir ./node init ./genesis.json
}

function networkReadParameters() {
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do

      key="$1"

      case $key in
          --nn|--name)
          mNode="$2"
          shift # past argument
          shift # past value
          ;;
          --ni|--id)
          chainId="$2"
          shift # past argument
          shift # past value
          ;;
          --nt|--ntype)
          nodeType="$2"
          shift # past argument
          shift # past value
          ;;
          --ip)
          pCurrentIp="$2"
          shift # past argument
          shift # past value
          ;;
          --r|--rpc)
          rPort="$2"
          shift # past argument
          shift # past value
          ;;
          --w|--whisper)
          wPort="$2"
          shift # past argument
          shift # past value
          ;;
          --t|--tessera)
          tPort="$2"
          shift # past argument
          shift # past value
          ;;
          --dt|--dtessera)
          dPort="$2"
          shift # past argument
          shift # past value
          ;;
          --raft)
          raPort="$2"
          shift # past argument
          shift # past value
          ;;
          --ws)
          wsPort="$2"
          shift # past argument
          shift # past value
          ;;
          *)    # unknown option
          POSITIONAL+=("$1") # save it in an array for later
          shift # past argument
          ;;
      esac
  done
  set -- "${POSITIONAL[@]}" # restore positional parameters

  if [[ -z "$mNode" && -z "$chainId" && -z "$nodeType" && -z "$pCurrentIp" && -z "$rPort" && -z "$wPort" && -z "$tPort" && -z "$raPort" && -z "$dPort" && -z "$wsPort" && -z "$networkName" ]]; then
      return
  fi

  if [[ -z "$mNode" || -z "$chainId" || -z "$nodeType" || -z "$pCurrentIp" || -z "$rPort" || -z "$wPort" || -z "$tPort" || -z "$raPort" || -z "$dPort" || -z "$wsPort" || -z "$networkName" ]]; then
      help
  fi

  NETWORK_NON_INTERACTIVE=true
}

function main(){

    networkReadParameters $@

    if [ -z "$NETWORK_NON_INTERACTIVE" ]; then
        getInputWithDefault 'Please enter network id' 1101 chainId $BLUE
        getInputWithDefault 'Please enter node name' "" mNode $BLUE
        #getInputWithDefault 'Please enter node type permissioned y/n' "y" nodeType $GREEN
        getInputWithDefault 'Please enter IP Address of this node' "127.0.0.1" pCurrentIp $PINK
        getInputWithDefault 'Please enter RPC Port of this node' 22000 rPort $PINK
        getInputWithDefault 'Please enter Network Listening Port of this node' $((rPort+1)) wPort $GREEN
        getInputWithDefault 'Please enter Tessera Port of this node' $((wPort+1)) tPort $GREEN
        getInputWithDefault 'Please enter Tessera debug Port of this node' $((tPort+1)) dPort $GREEN
        getInputWithDefault 'Please enter Raft Port of this node' $((dPort+1)) raPort $PINK
        getInputWithDefault 'Please enter WS Port of this node' $((raPort+1)) wsPort $GREEN
    fi

    cleanup
    generateKeyPair
    createAccount
    generateEnode
    createSetupConf
    copyScripts
    generateTesseraConfig
    executeInit
}

main $@
