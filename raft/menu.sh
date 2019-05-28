#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source variables
source raft/common.sh

function init() {

	echo -e $GREEN'Start deployment quorum Network, Built on version 2.2.1\n'
}

function networkReadParameters() {
    POSITIONAL=()
    while [[ $# -gt 0 ]]
    do
        key="$1"

        case $key in
          create)
            option="1"
            shift # past argument
            ;;
          join)
            option="2"
            shift # past argument
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

	if [[ ! -z $option && $option -lt 1 || $option -gt 4 ]]; then
		help
	fi

	if [ ! -z $option ]; then
		NETWORK_NON_INTERACTIVE=true
	fi
}

function main() {

	init

	networkReadParameters $@

	if [ -z "$NETWORK_NON_INTERACTIVE" ]; then
		flagmain=true
		echo -e $YELLOW'Please select an option: \n' \
				$GREEN'1) Create Network \n' \
				$PINK'2) Join Network \n'

		printf $WHITE'option: '$COLOR_END

		read option
	fi

	createOrJoin="$option";

	case $createOrJoin in
		1)
      echo -e $YELLOW'Creating your Raft network \n'
			raft/create_network.sh
			cd ${nodeName}/
			$@;;
			#./node_start.sh
			#tail -f /dev/null $@;;
		2)
      echo -e $YELLOW'joining to the existing network \n'
			raft/join_network.sh
			cd ${nodeName}/
			$@;;
			#./node_start.sh
			#tail -f /dev/null $@;;
		*)
			echo -e $RED'Please enter a valid option'	;;
	esac
    echo $WHITE
}

main $@
