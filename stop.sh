#!/bin/bash
##################################################################################
#                                                    #
# Quorum 2.2.1                                                                               #
#                                                         #
##################################################################################

killall geth bootnode constellation-node

if [ "`jps | grep tessera`" != "" ]
then
  jps | grep tessera | cut -d " " -f1 | xargs kill
else
  echo "tessera: no process found"
fi
