#!/bin/bash

source variables
source clique/common.sh

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

#function to get signers
function getSigners() {
    result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_coinbase\",\"params\":[],\"id\":2}"`
    result=$(echo $result | awk -F ":|}| " '{print $4}')

    echo "Signers: " $result
    temp="${result%\"}"
    result="${temp#\"}"
    acc_signers=${result#"0x"}
    echo "genesis signers: " $acc_signers

    #IFS=',][' read -a array <<< "${result%}"
    # echo "signers: " ${array[@]}
    # result=$( echo ${array[-1]} )
    # temp="${result%\"}"
    # result="${temp#\"}"
    # acc_signers=${result#"0x"}
    # echo "genesis signers: " $acc_signers
    
    # IFS=',()]["' read -r -a array <<<$result
    # result=$( echo ${array[2]} )
    # acc_signers=${result#"0x"}
    # echo "signers: " $acc_signers
}

#function to create start node script
function copyScripts(){
    
    cp ../../template/genesis_template_clique.json ../genesis.json
    sed -i "s|#CHAIN_ID#|${chainId}|g" ../genesis.json
    sed -i "s|#mNodeAddress#|${acc_signers}|g" ../genesis.json
    
    cp ../../template/tessera_start_template.sh ../tessera_start.sh   
    cp ../../template/node_start_template_clique.sh ../node_start.sh

    echo ${password} > ../password.txt
    
    sed -i "s/#DPORT/${dPort}/g" ../tessera_start.sh
    sed -i "s/#NODE/'${mNode}'/g" ../tessera_start.sh
    sed -i "s/#NODE/'${mNode}'/g" ../node_start.sh
    
    if [ "$nodeType" = 'y' ];
    then
        sed -i "s|authorityNode=''|authorityNode='${nodeType}'|g" ../node_start.sh
    fi

    NETWORK_ID=$(cat ../genesis.json | grep chainId | awk -F " " '{print $2}' | awk -F "," '{print $1}')

    ARGS="--nodiscover --networkid $NETWORK_ID --syncmode full --mine --minerthreads 1 --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,clique"

    pattern="--rpcport ${rPort} --port ${wPort}"

    sed -i "s/#STARTCMD/${pattern}/g" ../node_start.sh
}

#function to gconfigure tessera
function generateTesseraConfig(){
    echo "[*] Generating tessera configuration"
    rm -rf tesseraConfig
    # Create logs and tessera config directory
    mkdir tesseraConfig
    mkdir -p qdata/logs
    # Generate keys
    echo "tessera path: " $tesseraJar

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
	Enode="enode://"$(bootnode -nodekey nodekey -verbosity 9 -writeaddress)"@"
    mv nodekey geth/.
    cp ../../template/static-nodes_template_raft.json static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#CURRENT_IP#|${pCurrentIp}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#W_PORT#|${wPort}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#raftPprt#|${raPort}|g"
    sed -i $PATTERN static-nodes.json
    peerEnode=${Enode}${pCurrentIp}":"${wPort}"?discport=0"
    echo "peerEnode: " $peerEnode
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

#add peers enodeId
function addPeers(){

    nodeId=`sed 's/\[\|\]\|\"'//g static-nodes.json`
    echo ${nodeId} 

    result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"admin_addPeer\",\"params\":[\"${nodeId}\"],\"id\":2}"`
    echo "result: " $result
    result=$(echo $result | awk -F ":|}| " '{print $4}')
	echo "admin_addPeer result: " $result
    
    if [ "$result" = true ];
        then
            echo "peer added successfully!"
        else 
            echo "peer not added"
            #exit 1
    fi
    sleep 5
    result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"admin_peers\",\"params\":[],\"id\":2}"`
    echo $result | jq '.result'>temp.json
    echo $result
    jq -c '.[]' temp.json | while read i; do
        network=$( echo $i | jq -r '.network' )
        ip=$( echo $network | jq -r '.remoteAddress' )
        IFS=':' read -r -a array <<<$ip
        echo "remoteAddress: " ${array[0]}
        result=`curl -X POST "http://${array[0]}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"admin_addPeer\",\"params\":[\"${nodeId}\"],\"id\":2}"`
        echo "result: " $result
        result=$(echo $result | awk -F ":|}| " '{print $4}')
        echo "admin_addPeer result: " $result
    done

    rm temp.json
}

#add authority node
function addAuthorityNode() {

    if [ "$nodeType" = 'y' ];
        then
            result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"clique_propose\",\"params\":[\"${acc_address}\", true],\"id\":2}"`
            echo "result: " $result
            result=$(echo $result | awk -F ":|}| " '{print $4}')
            echo "clique_propose result: " $result
            
            if [ "$result" = "null" ];
                then
                    echo "successfully proposed for signer!"
                else 
                    echo "peer not proposed for signers"
                    #exit 1
            fi
            sleep 5
            result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"admin_peers\",\"params\":[],\"id\":2}"`
            echo $result | jq '.result'>temp.json
            echo $result
            jq -c '.[]' temp.json | while read i; do
                network=$( echo $i | jq -r '.network' )
                ip=$( echo $network | jq -r '.remoteAddress' )
                IFS=':' read -r -a array <<<$ip
                echo "remoteAddress: " ${array[0]}
                result=`curl -X POST "http://${array[0]}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"clique_propose\",\"params\":[\"${acc_address}\", true],\"id\":2}"`
                echo "result: " $result
                result=$(echo $result | awk -F ":|}| " '{print $4}')
                echo "clique_propose result: " $result
            done
    fi
    
    rm temp.json
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
          --pw)
          wPassword="$2"
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
          --mip)
          pMainIp="$2"
          shift # past argument
          shift # past value
          ;;
          --mport)
          pMainPort="$2"
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

  if [[ -z "$mNode" && -z "$chainId" && -z "$wPassword" && -z "$nodeType" && -z "$pCurrentIp" && -z "$pMainIp" && -z "$pMainPort" && -z "$rPort" && -z "$wPort" && -z "$tPort" && -z "$dPort" && -z "$wsPort" ]]; then
      return
  fi

  if [[ -z "$mNode" || -z "$chainId" || -z "$wPassword" || -z "$nodeType" || -z "$pCurrentIp" || -z "$pMainIp" || -z "$pMainPort" || -z "$rPort" || -z "$wPort" || -z "$tPort" || -z "$dPort" || -z "$wsPort" ]]; then
      help
  fi

  NETWORK_NON_INTERACTIVE=true
}

function main(){    

    networkReadParameters $@

    if [ -z "$NETWORK_NON_INTERACTIVE" ]; then
        getInputWithDefault 'Please enter network id' 1101 chainId $BLUE
        getInputWithDefault 'Please enter node name' "" mNode $BLUE
        getInputWithDefault 'Please enter password for wallet' "" wPassword $BLUE
        getInputWithDefault 'Please enter node type validator y/n' "y" nodeType $GREEN
        getInputWithDefault 'Please enter IP Address of main node' "127.0.0.1" pMainIp $PINK
        getInputWithDefault 'Please enter Port of main node' 22000 pMainPort $PINK
        getInputWithDefault 'Please enter IP Address of this node' "127.0.0.1" pCurrentIp $ORANGE
        getInputWithDefault 'Please enter RPC Port of this node' 22000 rPort $ORANGE
        getInputWithDefault 'Please enter Network Listening Port of this node' $((rPort+1)) wPort $GREEN
        getInputWithDefault 'Please enter Tessera Port of this node' $((wPort+1)) tPort $GREEN
        getInputWithDefault 'Please enter Tessera debug Port of this node' $((tPort+1)) dPort $GREEN
        getInputWithDefault 'Please enter WS Port of this node' $((dPort+1)) wsPort $GREEN
    fi 

    cleanup
    generateKeyPair
    createAccount
    generateEnode
    createSetupConf
    getSigners
    copyScripts
    generateTesseraConfig
    addPeers
    addAuthorityNode
    executeInit   
}

main $@
