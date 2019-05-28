#!/usr/bin/env bash
##################################################################################
#                                                                                #
# Quorum 2.2.1                                                                   #
#                                                                                #
##################################################################################


node=$1
tessera_port=$2

echo "[*] Initialising Tessera configuration"

currentDir=$(pwd)
DDIR="tesseraConfig/"
rm -f "${DDIR}/tm.ipc"

#change tls to "strict" to enable it (don't forget to also change http -> https)
cat <<EOF > ${DDIR}/tessera-config.json
{
    "useWhiteList": false,
    "jdbc": {
        "username": "sa",
        "password": "",
        "url": "jdbc:h2:./${DDIR}/db;MODE=Oracle;TRACE_LEVEL_SYSTEM_OUT=0"
    },
    "server": {
        "port": ${tessera_port},
        "hostName": "http://localhost",
        "sslConfig": {
            "tls": "OFF",
            "generateKeyStoreIfNotExisted": true,
            "serverKeyStore": "${currentDir}/tesseraConfig/server-keystore",
            "serverKeyStorePassword": "quorum",
            "serverTrustStore": "${currentDir}/tesseraConfig/server-truststore",
            "serverTrustStorePassword": "quorum",
            "serverTrustMode": "TOFU",
            "knownClientsFile": "${currentDir}/tesseraConfig/knownClients",
            "clientKeyStore": "${currentDir}/tesseraConfig/client-keystore",
            "clientKeyStorePassword": "quorum",
            "clientTrustStore": "${currentDir}/tesseraConfig/client-truststore",
            "clientTrustStorePassword": "quorum",
            "clientTrustMode": "TOFU",
            "knownServersFile": "${currentDir}/tesseraConfig/knownServers"
        }
    },
    "peer": [
        {
            "url": "http://localhost:${tessera_port}"
        }
    ],
    "keys": {
        "passwords": [],
        "keyData": [
            {
                "config": $(cat ${currentDir}/tesseraConfig/.key),
                "publicKey": "$(cat ${currentDir}/tesseraConfig/.pub)"
            }
        ]
    },
    "alwaysSendTo": [],
    "unixSocketFile": "${currentDir}/tesseraConfig/tm.ipc"
}
EOF
