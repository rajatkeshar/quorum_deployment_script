#!/bin/bash
source variables
source ${globalDir}/common.sh

checkRpcStatus() {
	while true
	do
		result=`curl -X POST "#RPC_URL#" -H "accept: application/json" -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"net_listening\",\"params\":[],\"id\":2}"`
		echo $result
		status=$(echo $result | awk -F ":|}| " '{print $4}')
		echo "helth status: " $status
		if [ "$status" = true ];
			then
				echo "Peer RPC is Helthy"
			else 
				echo "peer is Unhelthy, restarting node"
				./node_stop.sh
				./node_start.sh
		fi
		sleep 20
	done
}


main () {
	checkRpcStatus
}

main $@