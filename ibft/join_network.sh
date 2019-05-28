#!/bin/bash

source variables
source ibft/common.sh

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

#function to get validators
function getvalidators() {
    result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_coinbase\",\"params\":[],\"id\":2}"`
    result=$(echo $result | awk -F ":|}| " '{print $4}')

    echo "Validators: " $result
    temp="${result%\"}"
    result="${temp#\"}"
    acc_validators=${result#"0x"}
    echo "genesis validators: " $acc_validators
}

#function to create start node script
function copyScripts(){
    cp ../../template/genesis_template_ibft.json ../genesis.json
    sed -i "s|#CHAIN_ID#|${chainId}|g" ../genesis.json
    sed -i "s|#EXTRA_DATA#|${acc_validators}|g" ../genesis.json
    
    cp ../../template/tessera_start_template.sh ../tessera_start.sh   
    cp ../../template/node_start_template_ibft.sh ../node_start.sh

    echo ${password} > ../password.txt
    
    sed -i "s/#DPORT/${dPort}/g" ../tessera_start.sh
    sed -i "s/#NODE/'${mNode}'/g" ../tessera_start.sh
    sed -i "s/#NODE/'${mNode}'/g" ../node_start.sh
    pattern="--rpcport ${rPort} --port ${wPort}"
    sed -i "s/#STARTCMD/${pattern}/g" ../node_start.sh

    if [ "$nodeType" == "y" ];
		then
		    sed -i "s|validatorNode=''|validatorNode='$nodeType'|g" ../node_start.sh
	fi
    
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

    cp priv nodekey
    nodekey=$(cat nodekey)
	bootnode -nodekey nodekey -verbosity 9 -addr :30310 2>enode.txt &
	echo $enode
    pid=$!
	sleep 5
	kill -9 $pid
	wait $pid 2> /dev/null
	re="enode:.*@"
	enode=$(cat enode.txt)
    
    if [[ $enode =~ $re ]];
    	then
        Enode=${BASH_REMATCH[0]};
    fi
    cp nodekey geth/.
    cp ../../template/static-nodes_template_ibft.json static-nodes.json
    PATTERN="s|#eNode#|${Enode}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#CURRENT_IP#|${pCurrentIp}|g"
    sed -i $PATTERN static-nodes.json
    PATTERN="s|#W_PORT#|${wPort}|g"
    sed -i $PATTERN static-nodes.json

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
function addValidatorNode() {

    if [ "$nodeType" = 'y' ];
        then
            result=`curl -X POST "http://${pMainIp}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"istanbul_propose\",\"params\":[\"${acc_address}\", true],\"id\":2}"`
            echo "result: " $result
            result=$(echo $result | awk -F ":|}| " '{print $4}')
            echo "ibft_propose result: " $result
            
            if [ "$result" = "null" ];
                then
                    echo "successfully proposed for validator!"
                else 
                    echo "peer not proposed for validator"
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
                result=`curl -X POST "http://${array[0]}:${pMainPort}" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"istanbul_propose\",\"params\":[\"${acc_address}\", true],\"id\":2}"`
                echo "result: " $result
                result=$(echo $result | awk -F ":|}| " '{print $4}')
                echo "ibft_propose result: " $result
            done
    fi
    
    rm temp.json
}

function main(){    

    mNode="$nodeName" 

    cleanup
    generateKeyPair
    createAccount
    generateEnode
    createSetupConf
    getvalidators
    copyScripts
    generateTesseraConfig
    addPeers
    addValidatorNode
    executeInit   
}

main $@
