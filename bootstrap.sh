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
    sudo apt-get update
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get install -y software-properties-common 
    sudo apt-get install -y build-essential
    sudo apt-get install -y jq
    sudo apt-get install -y unzip 
    sudo apt-get install -y libdb-dev
    sudo apt-get install -y libleveldb-dev 
    sudo apt-get install -y libsodium-dev 
    sudo apt-get install -y zlib1g-dev 
    sudo apt-get install -y libtinfo-dev 
    sudo apt-get install -y solc 
    sudo apt-get install -y sysvbanner 
    sudo apt-get install -y maven
    sudo apt-get install -y openjdk-8-jdk 
    sudo apt-get install -y python-pip
    sudo apt-get install -y monit
}

function install_java(){
    sudo mkdir -p /usr/local/java
    dir=$(pwd)
    sudo cp jre-8u211-linux-x64.tar.gz /usr/local/java/
    cd /usr/local/java/
    sudo tar xzvf jre-8u211-linux-x64.tar.gz
    sudo update-alternatives --install "/usr/bin/java" "java" "/usr/local/java/jre1.8.0_211/bin/java" 1 
    sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/local/java/jre1.8.0_211/bin/javaws" 1 
    sudo update-alternatives --set java /usr/local/java/jre1.8.0_211/bin/java
    sudo update-alternatives --set javaws /usr/local/java/jre1.8.0_211/bin/javaws
    export JAVA_HOME=/usr/local/java/jre1.8.0_211
    export PATH=$JAVA_HOME/bin:$PATH
    echo 'export JAVA_HOME=/usr/local/java/jre1.8.0_211' >> ~/.bashrc
    echo "export PATH=$JAVA_HOME/bin:$PATH" >> ~/.bashrc
    cd ${dir}
    echo ${dir}
    
}

function install_tessera(){
    wget -q https://github.com/jpmorganchase/tessera/releases/download/tessera-0.6/tessera-app-0.6-app.jar
    mkdir tessera
    sudo mv ./tessera-app-0.6-app.jar ${PWD}/tessera/tessera.jar
    echo "export  TESSERA_JAR=${PWD}/tessera/tessera.jar" >> ~/.profile
    echo "export TESSERA_JAR=${PWD}/tessera/tessera.jar" >> ~/.bashrc
    export TESSERA_JAR=${PWD}"/tessera/tessera.jar"
    source ~/.profile
    source ~/.bashrc
}

function install_go(){
    # install golang
    GOREL=go1.9.7.linux-amd64.tar.gz
    wget -q https://dl.google.com/go/$GOREL
    tar xfz $GOREL
    sudo mv go /usr/local/go
    rm -f $GOREL
    PATH=$PATH:/usr/local/go/bin
    echo 'PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo "export GOPATH=${PWD}/go/build/_workspace" >> ~/.bashrc
    export GOPATH=${PWD}/go/build/_workspace
    source ~/.profile
    source ~/.bashrc
}

function install_quorum(){
    # make/install testnet
    git clone https://github.com/jpmorganchase/quorum.git
    pushd quorum >/dev/null
    go get github.com/urfave/cli
    make geth bootnode
    sudo cp build/bin/geth /usr/local/bin
    sudo cp build/bin/bootnode /usr/local/bin
    popd >/dev/null
    rm -rf quorum
}

function install_porosity(){
    # install Porosity
    wget -q https://github.com/jpmorganchase/quorum/releases/download/v1.2.0/porosity
    sudo mv porosity /usr/local/bin && chmod 0755 /usr/local/bin/porosity
}

function main(){
    pack
    install_java
    install_tessera
    install_go
    install_quorum
    install_porosity

    echo -n "Do you want to download ipfs (y/n)? "
    read answer

    if [[ "$answer" != "${answer#[Yy]}" ]]; then
        install_docker
        install_ipfs
        exit 0
    fi

    # done!
    banner "Done"
    echo
}

main
