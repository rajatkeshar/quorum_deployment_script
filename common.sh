
RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[1;34m'
PINK=$'\e[1;35m'
CYAN=$'\e[1;96m'
WHITE=$'\e[1;39m'
COLOR_END=$'\e[0m'

function getInputWithDefault() {
    local msg=$1
    local __defaultValue=$2
    local __resultvar=$3
    local __clr=$4

    if [ -z "$__clr" ]; then

        __clr=$RED

    fi

    if [ -z "$__defaultValue" ]; then

       read -p $__clr"$msg: "$COLOR_END __newValue
    else
        read -p $__clr"$msg""[Default:"$__defaultValue"]:"$COLOR_END __newValue
    fi


    if [ -z "$__newValue" ]; then

        __newValue=$__defaultValue

    fi

    eval $__resultvar="'$__newValue'"
}

function updateProperty() {
    local file=$1
    local key=$2
    local value=$3

    if grep -q $key= $file; then
        sed -i "s/$key=.*/$key=$value/g" $file
    else
        echo "" >> $file
        echo $key=$value >> $file
    fi
    sed -i '/^$/d' $file
}

function displayProgress(){
    local __TOTAL=$1
    local __CURRENT=$2

    let __PER=$__CURRENT*100/$__TOTAL

    local __PROG=""

    local __j=0
    while : ; do

        if [ $__j -lt $__PER ]; then
            __PROG+="\xE2\x96\x90"
        else
            __PROG+=" "
        fi

        if [ $__j -eq 100 ]; then
            break;
        fi
        let "__j+=2"
    done

    echo -ne ' ['${YELLOW}"${__PROG}"${COLOR_END}']'$GREEN'('$__PER'%)'${COLOR_END}'\r'

    if [ $__TOTAL -eq $__CURRENT ]; then
            echo ""
            break;
    fi

}

function help(){
    echo ""
    echo -e $WHITE'Usage ./setup.sh [COMMAND] [OPTIONS]'$COLOR_END
    echo ""
    echo "Utility to setup Quorum Network"
    echo ""
    echo "Commands:"
    echo -e $GREEN'create'$COLOR_END    "   Create a new Node. The node hosts Quorum, Constellation and Node Manager"
    echo -e $PINK'join'$COLOR_END       "     Create a node and Join to existing Network"
    echo -e $CYAN'dev'$COLOR_END        "      Create a development/test network with multiple nodes"
    echo ""
    echo "Options:"
    echo ""
    echo -e $GREEN'For create command:'$COLOR_END
    echo "Create Network: "
    echo "E.g."
    echo "./setup.sh --c raft --nwState 1 --ni 1101 --nn node1 --pw password1234 --ip 127.0.0.1 --r 22000 --w 22001 --t 22002 --dt 22003 --raft 22004 --ws 22005"
    echo ""
    echo "  --c, --consensus        Consensus <raft, ibft, poa>"
    echo "  --nwState               Network State <1:create, 2:join, 3:dev_network>"
    echo "  --nn, --name            Node name"
    echo "  --ni, --id              NetworkId / ChainId"
    echo "  --pw                    Node Password"
    echo "  --nt, --ntype           Node Type <Validator/Non-Validator>"
    echo "  --ip                    IP address of this node (IP of the host machine)"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  --t, --tessera          Tessera port of this node"
    echo "  --td, --dtessera        DB Tessera port of this node"
    echo "  --raft                  Raft port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo ""
    echo -e $PINK'For join command:'$COLOR_END
    echo "Join Network: "
    echo "E.g."
    echo "./setup.sh --c raft --nwState 2 --ni 1101 --nn node2 --pw password1234 --ip 127.0.0.1 --mip 127.0.0.1 --mport 22000 --r 22007 --w 22008 --t 22009 --dt 22010 --raft 22011 --ws 22012"
    echo ""
    echo "  --c, --consensus        Consensus <raft, ibft, poa>"
    echo "  --nwState               Network State <1:create, 2:join, 3:dev_network>"
    echo "  --nn, --name            Node name"
    echo "  --ni, --id              NetworkId / ChainId"
    echo "  --pw                    Node Password"
    echo "  --nt, --ntype           Node Type <Validator/Non-Validator>"
    echo "  --ip                    IP address of this node (IP of the host machine)"
    echo "  --mip                   IP address of main running node"
    echo "  --mport                 Port of main node"
    echo "  -r, --rpc               RPC port of this node"
    echo "  -w, --whisper           Discovery port of this node"
    echo "  --t, --tessera          Tessera port of this node"
    echo "  --td, --dtessera        DB Tessera port of this node"
    echo "  --raft                  Raft port of this node"
    echo "  --ws                    Web Socket port of this node"
    echo ""
    echo -e $CYAN'For dev command:'$COLOR_END
    echo "Create development/network"
    echo "  -p, --project           Project Name"
    echo "  -n, --nodecount         Number of nodes to be created"
    echo "  -e, --expose            Expose docker container ports (Optional)"
    echo "  -t, --tessera           Create node with Tessera Support (Optional)"
    echo ""
    echo "E.g."
    echo "./setup.sh dev -p TestNetwork -n 3"
    echo ""
    echo "-h, --help              Display this help and exit"

    exit
}

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}
