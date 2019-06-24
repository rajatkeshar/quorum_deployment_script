source variables
source raft/common.sh

function createOrJoin() {

    port_no=$(grep "next_port=" network.conf | awk -F = '{print $2}')
    node_no=$(grep "node_number=" network.conf | awk -F = '{print $2}')
    echo "port_no: " $port_no
    echo "node_no: " $node_no
    echo "pwd: " $(pwd)
    for (( i=1; i<=$nodeCount; i++))
    do
        ../raft/create_network.sh --id 1101 --nn "node"${node_no} --pw "node"${node_no} --ip 0.0.0.0 --r ${port_no} --w $((port_no + 1))  --t $((port_no + 2)) --dt $((port_no + 3)) --raft $((port_no + 4)) --ws $((port_no + 5))

		# if [[ "node"${node_no} != "node1" || ${option} != "1" ]]
		# then

        #     sleep 10
		# 	../raft/join_network.sh --id 1101 --nn "node"${node_no} --pw "node"${node_no} --ip 0.0.0.0 --r --mip 0.0.0.0 --mport 22000 ${port_no} --w $((port_no + 1))  --t $((port_no + 2)) --dt $((port_no + 3)) --raft $((port_no + 4)) --ws $((port_no + 5)) 
		# else
		# 	cd ${networkName}/qdata/"node"${node_no}
		# 	./node_start.sh
		# 	cd ../../../raft
		# fi

        replace_port_no=$((port_no + 6))
        replace_node_no=$((node_no + 1))
        sed -i "s/next_port=${port_no}/next_port=${replace_port_no}/g"  ../${networkName}/network.conf
        sed -i "s/node_number=${node_no}/node_number=${replace_node_no}/g"  ../${networkName}/network.conf
		port_no=${replace_port_no}
		node_no=${replace_node_no}
    done
}

function cleanup(){
    rm -rf ${networkName}
    echo $networkName > .networkName
    mkdir ${networkName}
    echo 'next_port=22000' > ${networkName}/network.conf
    echo 'node_number=1' >> ${networkName}/network.conf
    cp variables $networkName
    cd ${networkName}
    #cd ${mNode}/node/
}

function readParameters() {
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
            --nn|--network)
            networkName="$2"
            shift # past argument
            shift # past value
            ;;
            --nc|--nodecount)
            nodeCount="$2"
            shift # past argument
            shift # past value
            ;;
            --e|--expose)
            exposePorts="true"
            shift # past argument
            shift # past value
            ;;
            --t|--tessera)
            tessera="true"
            shift # past argument
            shift # past value
            ;;
            -h|--help)
            help  
            ;;
            *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters

    if [[ -z "$networkName" && -z "$nodeCount" ]]; then
        return
    fi

    if [[ -z "$networkName" || -z "$nodeCount" ]]; then
        help
    fi

    NON_INTERACTIVE=true
}

function main(){    

    readParameters $@

    if [ -z "$NON_INTERACTIVE" ]; then
        getInputWithDefault 'Please enter a network name' "TestNetwork" networkName $RED
        getInputWithDefault 'Please enter number of nodes to be created' 3 nodeCount $GREEN
    fi
   
    echo -e $BLUE'Creating '$networkName' with '$nodeCount' nodes. Please wait... '$COLOR_END
    
    cleanup

    createOrJoin
    
    displayProgress $nodeCount 0

    
    echo -e $GREEN'Network '$networkName' created successfully. Check '$networkName' directory'$COLOR_END
}
main $@