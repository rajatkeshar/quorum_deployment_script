#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source variables
source common.sh

function call() {

	if [[ "$consensus" == "raft" ]]
		then
			raft/menu.sh $@
	fi

	if [[ "$consensus" == "POA" ]]
	then
			clique/menu.sh $@
	fi

	if [[ "$consensus" == "ibft" ]]
	then
			ibft/menu.sh $@
	fi
}

function init() {

	echo -e $WHITE'\nStart deployment quorum Network, Built on version 2.2.1\n'
}

function networkReadParameters(){
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do

        key="$1"

        case $key in
            --c|--consensus)
            consensus="$2"
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
    if [[ -z "$consensus" ]]; then
        return
    fi

    NETWORK_NON_INTERACTIVE=true
}

function networkReadInputs(){
    if [[ -z "$NETWORK_NON_INTERACTIVE" ]]; then
			  getInputWithDefault 'Select consensus type (raft/ibft/POA) ' "" consensus $BLUE
    fi
}

main(){
		init
    networkReadParameters $@
    networkReadInputs
    call $@
}

main $@
