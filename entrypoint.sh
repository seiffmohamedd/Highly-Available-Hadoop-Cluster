#!/bin/bash

case $(hostname) in
  master1|master2|master3)
    NODE_TYPE="master"
    ;;
  *)
    NODE_TYPE="worker"
    ;;
esac

if [[ $NODE_TYPE == "master" ]]; then
  case $(hostname) in
    master1) echo "1" > $ZOOKEEPER_HOME/data/myid ;;
    master2) echo "2" > $ZOOKEEPER_HOME/data/myid ;;
    master3) echo "3" > $ZOOKEEPER_HOME/data/myid ;;
  esac
fi

# Start SSH
sudo service ssh start

# Start services based on node type
if [[ $NODE_TYPE == "master" ]]; then
  # Start ZooKeeper
  $ZOOKEEPER_HOME/bin/zkServer.sh start
  
  # Start JournalNode
  hdfs --daemon start journalnode
  
  # Initialize ZKFC if master1
  if [[ $(hostname) == "master1" ]]; then
    hdfs zkfc -formatZK
    # format namenode
  fi
  
  # Start NameNode and ZKFC
  hdfs --daemon start namenode
  hdfs --daemon start zkfc
  
  # Start ResourceManager
  yarn --daemon start resourcemanager
else
  # Worker node services
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi

# Keep container running
tail -f /dev/null