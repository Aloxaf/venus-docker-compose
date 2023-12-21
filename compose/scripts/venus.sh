#!/bin/bash
set -e

if [[ -d ~/.venus ]];then
    /app/venus daemon
else

    Args=" --auth-url=http://auth:8989 "

    while [ ! -f /env/token ] ; do
        echo "wait token ..."
        sleep 5
    done
    token=$(cat /env/token )
    Args="$Args --auth-token=$token"

    if [ ! -z $NET_TYPE ]
    then
        Args="$Args --network=$NET_TYPE"
    fi

    if [ ! -z $SNAP_SHOT ]
    then
        Args="$Args --import-snapshot=/root/snapshot.car.zst"
    fi

    if [ -z $SNAP_SHOT  ] && [ ! -z $GEN_FILE ] 
    then
        Args="$Args --genesisfile=/root/genesis.car"
    fi

    # if not mainnet,calibrationnet,butterflynet, wait for bootstrap
    if [ ! -z $NET_TYPE ] && [ $NET_TYPE != "mainnet" ] && [ $NET_TYPE != "calibrationnet" ] && [ $NET_TYPE != "butterflynet" ]
    then
        while [ ! -f /env/bootstrap ] ; do
            echo "wait bootstrap ..."
            sleep 5
        done
        bootstraper=$(cat /env/bootstrap )
        Args="$Args --bootstrap-peers=$bootstraper"
    fi


    echo "EXEC: /app/venus daemon $Args \n\n"
    /app/venus daemon $Args &

    # restart to change api
    while [[ ! -f ~/.venus/config.json ]]; do
        echo "wait to restart ..."
        sleep 10
    done
    echo "restart ..."
    kill $!
    jq '.api.apiAddress="/ip4/0.0.0.0/tcp/3453" ' ~/.venus/config.json > ~/.venus/config.json.tmp
    mv -f ~/.venus/config.json.tmp ~/.venus/config.json 

    /app/venus daemon $Args
fi
