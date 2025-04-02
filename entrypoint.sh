#!/bin/bash

case $(hostname) in
  master11|master22|master33)
    NODE_TYPE="master"
    ;;
  *)
    NODE_TYPE="worker"
    ;;
esac

if [[ $NODE_TYPE == "master" ]]; then
  mkdir -p $ZOOKEEPER_HOME/data
  case $(hostname) in
    master11) echo "1" > $ZOOKEEPER_HOME/data/myid ;;
    master22) echo "2" > $ZOOKEEPER_HOME/data/myid ;;
    master33) echo "3" > $ZOOKEEPER_HOME/data/myid ;;
  esac
fi

sudo service ssh start

if [[ $NODE_TYPE == "master" ]]; then
  $ZOOKEEPER_HOME/bin/zkServer.sh start
  
  hdfs --daemon start journalnode
  
  if [[ $(hostname) == "master11" ]]; then
    # until hdfs dfsadmin -report 2>/dev/null; do
    #   echo "Waiting for JournalNodes to start..."
    #   sleep 5
    # done
    hdfs namenode -initializeSharedEdits -force
    hdfs namenode -format
    hdfs zkfc -formatZK -force
    hdfs --daemon start namenode
    
    # until hdfs haadmin -getServiceState nn1 2>/dev/null | grep -q "active"; do
    #   echo "Waiting for NameNode to become active..."
    #   sleep 5
    # done
    
    # for node in master22 master33; do
    #   hdfs namenode -bootstrapStandby -force
    # done
    
    hdfs dfs -mkdir -p /shared/logs
    hdfs dfs -chmod -R 777 /shared/logs
  fi
  if [[ $(hostname) != "master11" ]]; then
    hdfs namenode -bootstrapStandby -force
  fi
  hdfs --daemon start namenode
  hdfs --daemon start zkfc
  yarn --daemon start resourcemanager
else
  # until nc -z master11 8020; do
  #   echo "Waiting for master11 NameNode to be available..."
  #   sleep 10
  # done
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi

echo "Starting health check server..."
python3 -m http.server 8080 &

tail -f /dev/null

sleep infinity 