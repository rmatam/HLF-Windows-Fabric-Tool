#!/bin/bash

# Exit on first error
set -e
# Grab the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo
# check that the composer command exists at a version >v0.14
if hash composer 2>/dev/null; then
    composer --version | awk -F. '{if ($2<15) exit 1}'
    if [ $? -eq 1 ]; then
        echo 'Sorry, Use createConnectionProfile for versions before v0.15.0' 
        exit 1
    else
        echo Using composer-cli at $(composer --version)
    fi
else
    echo 'Need to have composer-cli installed at v0.15 or greater'
    exit 1
fi
# need to get the certificate 

CYGDIR="$(cygpath -pw "$DIR")"

if [[ ! -v DOCKER_HOST ]]; then
    echo "DOCKER_HOST is NOT set <<<< Please set the env for Docker !!!!"
    DOCKER_IP="localhost"
else
    
    DOCKER_IP="${DOCKER_HOST:6}"
    INDEX=`expr index "${DOCKER_IP}" :`
    echo $INDEX
    DOCKER_IP="${DOCKER_IP:0:(INDEX-1)}"
fi
echo  "Using the Docker VM IP Address: ${DOCKER_IP}"

#cat << EOF > /tmp/.connection.json
mkdir -p $DIR/temp;

cat << EOF > $DIR/temp/.connection.json
{
    "name": "hlfv1",
    "type": "hlfv1",
    "orderers": [
       { "url" : "grpc://$DOCKER_IP:7050" }
    ],
    "ca": { "url": "http://$DOCKER_IP:7054", "name": "ca.org1.example.com"},
    "peers": [
        {
            "requestURL": "grpc://$DOCKER_IP:7051",
            "eventURL": "grpc://$DOCKER_IP:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}
EOF

PRIVATE_KEY="${DIR}"/composer/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk
CERT="${DIR}"/composer/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem


# Changed by Raj to take care of the paths
PRIVATE_KEY="$(cygpath -pw "$PRIVATE_KEY")"
CERT="$(cygpath -pw "$CERT")"

if composer card list -n PeerAdmin@hlfv1 > /dev/null; then
    composer card delete -n PeerAdmin@hlfv1
fi
composer card create -p $CYGDIR/temp/.connection.json -u PeerAdmin -c "${CERT}" -k "${PRIVATE_KEY}" -r PeerAdmin -r ChannelAdmin --file $CYGDIR/temp/PeerAdmin@hlfv1.card

composer card import --file $CYGDIR/temp/PeerAdmin@hlfv1.card 

#rm -rf $CYGDIR/temp/.connection.json
#rm -rf $CYGDIR/temp/PeerAdmin@hlfv1.card
rm -rf $CYGDIR/temp

echo "Hyperledger Composer PeerAdmin card has been imported"
composer card list

