#!/bin/bash

# the first argument provided is a comma-separated list of all ZooKeeper servers in the ensemble:
export ZOOKEEPER_SERVERS=$1
export SERVER_ID=0
export SERVER_IP=127.0.0.1

if [ -z "$2" ]
  then
    SERVER_IP=$(curl -s 169.254.169.254/latest/meta-data/local-ipv4)
  else
    SERVER_IP=$2
fi

# create data and blog directories:
mkdir -p $dataDir
mkdir -p $dataLogDir

# now build the ZooKeeper configuration file:
ZOOKEEPER_CONFIG=
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"tickTime=$tickTime"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"dataDir=$dataDir"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"dataLogDir=$dataLogDir"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"clientPort=$clientPort"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"initLimit=$initLimit"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"syncLimit=$syncLimit"
ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"maxClientCnxns=$maxClientCnxns"
# Put all ZooKeeper server IPs into an array:
IFS=', ' read -r -a ZOOKEEPER_SERVERS_ARRAY <<< "$ZOOKEEPER_SERVERS"
export ZOOKEEPER_SERVERS_ARRAY=$ZOOKEEPER_SERVERS_ARRAY
# now append information on every ZooKeeper node in the ensemble to the ZooKeeper config:
for index in "${!ZOOKEEPER_SERVERS_ARRAY[@]}"
do
    ZKID=$(($index+1))
    ZKIP=${ZOOKEEPER_SERVERS_ARRAY[index]}
    echo "$ZKIP"
    echo "$SERVER_IP"
    if [ "$ZKIP" == "$SERVER_IP" ]
    then
        # if IP's are used instead of hostnames, every ZooKeeper host has to specify itself as follows
        ZKIP=0.0.0.0
        SERVER_ID=$ZKID
    fi
    echo "$ZKIP"
    echo "$SERVER_ID"
    ZOOKEEPER_CONFIG="$ZOOKEEPER_CONFIG"$'\n'"server.$ZKID=$ZKIP:2888:3888"
done

# create myID file:
echo "$SERVER_ID" | tee $dataDir/myid

# Finally, write config file:
echo "$ZOOKEEPER_CONFIG" | tee conf/zoo.cfg

# start the server:
/bin/bash bin/zkServer.sh start-foreground