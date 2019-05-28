#!/bin/bash

#Menu system for launching appropriate scripts based on user choice
source variables
source ibft/common.sh

function init() {

	echo -e $GREEN'Start deployment Quorum Network, Built on version 2.2.1\n'
}

function main() {

	init

	case $createOrJoin in
		1)
            echo -e $YELLOW'Creating your IBFT network \n'
			ibft/create_network.sh
			cd ${nodeName}/
			./node_start.sh
			tail -f /dev/null $@;;
		2)
            echo -e $YELLOW'joining to the existing IBFT network \n'
			ibft/join_network.sh
			cd ${nodeName}/
			./node_start.sh
			tail -f /dev/null $@;;
		*)
			echo -e $RED'Please enter a valid option'	;;
	esac
    echo $WHITE
}

main $@
