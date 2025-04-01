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
  mkdir -p $ZOOKEEPER_HOME/data
  case $(hostname) in
    master1) echo "1" > $ZOOKEEPER_HOME/data/myid ;;
    master2) echo "2" > $ZOOKEEPER_HOME/data/myid ;;
    master3) echo "3" > $ZOOKEEPER_HOME/data/myid ;;
  esac
fi

sudo service ssh start

if [[ $NODE_TYPE == "master" ]]; then
  $ZOOKEEPER_HOME/bin/zkServer.sh start
  
  hdfs --daemon start journalnode
  
  if [[ $(hostname) == "master1" ]]; then
    until hdfs dfsadmin -report 2>/dev/null; do
      echo "Waiting for JournalNodes to start..."
      sleep 5
    done
    
    hdfs namenode -initializeSharedEdits -force
    
    hdfs namenode -format -clusterId hacluster -force
    
    hdfs zkfc -formatZK -force
    
    hdfs --daemon start namenode
    
    until hdfs haadmin -getServiceState nn1 2>/dev/null | grep -q "active"; do
      echo "Waiting for NameNode to become active..."
      sleep 5
    done
    
    for node in master2 master3; do
      ssh -o StrictHostKeyChecking=no $node "hdfs namenode -bootstrapStandby -force"
    done
    
    hdfs dfs -mkdir -p /shared/logs
    hdfs dfs -chmod -R 777 /shared/logs
  else
    until nc -z master1 8020; do
      echo "Waiting for master1 to initialize cluster..."
      sleep 10
    done
  fi
  
  hdfs --daemon start namenode
  hdfs --daemon start zkfc
  
  yarn --daemon start resourcemanager
else
  until nc -z master1 8020; do
    echo "Waiting for master1 NameNode to be available..."
    sleep 10
  done
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi

echo "Starting health check server..."
python3 -m http.server 8080 &

tail -f /dev/null