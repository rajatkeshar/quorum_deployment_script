#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source variables
source common.sh

function call() {

    case $networkState in
		1)
      		echo -e $YELLOW"Creating your $consensus network \n"
			$consensus/create_network.sh $@
			cd $(cat .nodename)
			./node_start.sh $@
            startMonit $@;;
			#tail -f /dev/null $@;;
		2)
      		echo -e $YELLOW"joining to the existing $consensus network \n"
			$consensus/join_network.sh $@
			cd $(cat .nodename)
			./node_start.sh $@;;
			#tail -f /dev/null $@;;
		3)
			echo -e $YELLOW"Creating Your Development/Test Network with $consensus consensus \n"
			$consensus/create_dev_network.sh $@;;
            #tail -f /dev/null $@;;
		4)
			echo -e $YELLOW"Exit"
			flagmain=false	;;
		*)
			echo -e $RED'Please enter a valid option'	;;
	esac
    echo $WHITE
}

#function to start monit
function startMonit(){
  echo "[*] Starting Monit"
  monit reload
  monit -t
  service monit restart
  monit restart all
}

function init() {

	echo -e $WHITE'\nStart deployment quorum Network, Built on version 2.2.1\n'
    echo globalDir=$(pwd) > variables
    echo TESSERA_JAR=$TESSERA_JAR >> variables
}

function variableConf() {
    if [[ "$consensus" == "raft" || "$consensus" == "RAFT" ]]
		then
			consensus="raft"
	fi

	if [[ "$consensus" == "ibft" || "$consensus" == "IBFT" ]]
	then
			consensus="ibft"
	fi

    if [[ "$consensus" == "poa" || "$consensus" == "POA" ]]
	then
			consensus="clique"
	fi
}

function networkReadParameters(){
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do

        key="$1"

        case $key in
            --nwState|--networkState)
            networkState="$2"
            shift # past argument
            shift # past value
            ;;
            --c|--consensus)
            consensus="$2"
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
    
    if [[ -z "$networkState" && -z "$consensus" ]]; then
        return
    fi

    NETWORK_NON_INTERACTIVE=true
}

function networkReadInputs(){
    if [[ -z "$NETWORK_NON_INTERACTIVE" ]]; then
        flagmain=true
        echo -e $YELLOW'Please select an option: \n' \
            $GREEN'1) Create Network \n' \
            $PINK'2) Join existing Network \n' \
            $CYAN'3) Setup Development/Test Network \n' \
            $RED'4) Exit'

            printf $WHITE'option: '$COLOR_END
        read networkState
        getInputWithDefault 'Select consensus type (raft/ibft/POA) ' "" consensus $BLUE
    fi
}

main(){
	init
    networkReadParameters $@
    networkReadInputs
    variableConf
    call $@
}

main $@
