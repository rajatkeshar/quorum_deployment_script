#!/bin/bash

##################################################################################
#                                                                                #
# Quorum 2.2.1                                                                   #
#                                                                                #
##################################################################################

source ../variables

set -u
set -e

dPort=#DPORT
node=#NODE
tesseraJar=$TESSERA_JAR
echo "curr_path: " $(pwd)
echo "tessera_start.sh tessera path: " $tesseraJar
remoteDebug=true
jvmParams=

if [  "${tesseraJar}" == "" ]; then
  echo "ERROR: unable to find Tessera jar file using TESSERA_JAR envvar, or using ${defaultTesseraJarExpr}"
  usage
elif [  ! -f "${tesseraJar}" ]; then
  echo "ERROR: unable to find Tessera jar file: ${tesseraJar}"
  usage
fi

currentDir=`pwd`
DDIR="node/tesseraConfig"
mkdir -p logs
rm -f "$DDIR/tm.ipc"

DEBUG=""
if [ "$remoteDebug" == "true" ]; then
  DEBUG="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${dPort} -Xdebug"
fi

#Only set heap size if not specified on command line
MEMORY=
if [[ ! "$jvmParams" =~ "Xm" ]]; then
  MEMORY="-Xms128M -Xmx128M"
fi

CMD="java $jvmParams $DEBUG $MEMORY -jar ${tesseraJar} -configfile $DDIR/tessera-config.json"
echo "$CMD >> logs/tessera-${node}.log 2>&1 &"
${CMD} >> "logs/tessera-${node}.log" 2>&1 &
sleep 1

echo "Waiting until all Tessera nodes are running..."
DOWN=true
k=10
while ${DOWN}; do
    sleep 1
    DOWN=false
    if [ ! -S "node/tesseraConfig/tm.ipc" ]; then
        echo "Node ${node} is not yet listening on tm.ipc"
        DOWN=true
    fi

    set +e
    result=$(printf 'GET /upcheck HTTP/1.0\r\n\r\n' | nc -Uv node/tesseraConfig/tm.ipc | tail -n 1)
    set -e
    if [ ! "${result}" == "I'm up!" ]; then
        echo "Node ${node} is not yet listening on http"
        DOWN=true
    fi

    k=$((k - 1))
    if [ ${k} -le 0 ]; then
        echo "Tessera is taking a long time to start.  Look at the Tessera logs in ${node}/logs/ for help diagnosing the problem."
    fi
    echo "Waiting until all Tessera nodes are running..."

    sleep 5
done
echo "All Tessera nodes started"
exit 0
