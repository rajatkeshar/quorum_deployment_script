#!/bin/bash

##################################################################################
#                                                                                #
# Quorum version 2.2.1
#                                                                                #
##################################################################################
set -eu -o pipefail


function install_docker(){

    # remove old docker
    sudo apt-get --assume-yes remove docker docker-engine docker.io
    sudo apt-get update

    # install package
    sudo apt-get --assume-yes install  apt-transport-https ca-certificates curl software-properties-common

    # Add Docker’s official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Install docker
    sudo apt-get update
    sudo apt-get --assume-yes install docker-ce
}

function install_ipfs(){
    # install ipfs
    git clone https://github.com/ipfs/go-ipfs
    cd go-ipfs
    sudo docker build -t ipfs_host_static .
    sudo docker run -d -p 8210:4001 -p 8211:5001 -p 8212:8080 ipfs_host_static
}

function pack(){
    # install build deps
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo add-apt-repository -y ppa:webupd8team/java
    sudo apt-get update
    # sudo add-apt-repository ppa:chris-lea/libsodium
    #apt-get install -y build-essential unzip libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev solc sysvbanner wrk software-properties-common default-jdk maven
    sudo apt-get install -y build-essential unzip libdb-dev libleveldb-dev libsodium-dev zlib1g-dev libtinfo-dev solc sysvbanner software-properties-common default-jdk maven python-pip

    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
    sudo apt-get install -y oracle-java8-installer
    #sudo pip install -r package.txt
}
function install_tessera(){
    wget -q https://github.com/jpmorganchase/tessera/releases/download/tessera-0.6/tessera-app-0.6-app.jar
    sudo cp ./tessera-app-0.6-app.jar ${PWD}/tessera/tessera.jar
    echo "export  TESSERA_JAR=${PWD}/tessera/tessera.jar" >> ~/.profile
    echo "export TESSERA_JAR=${PWD}/tessera/tessera.jar" >> ~/.bashrc
    export TESSERA_JAR=${PWD}"/tessera/tessera.jar"
    source ~/.profile
    source ~/.bashrc
}

function install_go(){
    # install golang
    GOREL=go1.11.1.linux-amd64.tar.gz
    wget -q https://dl.google.com/go/$GOREL
    tar xfz $GOREL
    sudo mv go /usr/local/go
    rm -f $GOREL
    PATH=$PATH:/usr/local/go/bin
    echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo "export GOPATH=${PWD}/testnet/build/_workspace" >> ~/.bashrc
    export GOPATH=${PWD}/testnet/build/_workspace
    source ~/.profile
    source ~/.bashrc
}

function install_testnet(){
    # make/install testnet
    git clone https://github.com/jpmorganchase/quorum.git
    pushd quorum >/dev/null
    go get github.com/urfave/cli
    make all
    sudo cp build/bin/geth /usr/local/bin
    sudo cp build/bin/bootnode /usr/local/bin
    sudo cp build/bin/ibftUtils /usr/local/bin
    popd >/dev/null
}

function install_porosity(){
    # install Porosity
    wget -q https://github.com/jpmorganchase/quorum/releases/download/v1.2.0/porosity
    sudo mv porosity /usr/local/bin && chmod 0755 /usr/local/bin/porosity
}

function main(){
    #pack
    install_tessera
    install_go
    install_testnet
    install_porosity

    echo -n "Do you want to download ipfs (y/n)? "
    read answer

    if [[ "$answer" != "${answer#[Yy]}" ]]; then
        install_docker
        install_ipfs
        exit 0
    fi

    # done!
    banner "Quorum 2.2.1"
    echo
}

main
