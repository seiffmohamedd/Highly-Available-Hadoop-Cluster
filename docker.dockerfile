FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    HADOOP_VERSION=3.3.6 \
    ZOOKEEPER_VERSION=3.8.4 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HADOOP_HOME=/opt/hadoop \
    ZOOKEEPER_HOME=/opt/zookeeper \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin:/opt/zookeeper/bin

# Install base packages with version pinning
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk=8u372-ga~22.04.1 \
    openssh-server=1:8.9p1-3ubuntu0.6 \
    rsync=3.2.7-1ubuntu1 \
    curl=7.81.0-1ubuntu1.15 \
    net-tools=1.60+git20181103.0eebece-1ubuntu5 \
    vim=2:8.2.3995-1ubuntu2.13 \
    iputils-ping=3:20211215-1 \
    netcat-openbsd=1.218-4ubuntu1 \
    python3=3.10.12-1~22.04 \
    sudo=1.9.9-1ubuntu2.4 \
    && rm -rf /var/lib/apt/lists/*

# Create hadoop user and directories
RUN useradd -ms /bin/bash hadoop && \
    mkdir -p /opt/hadoop /opt/zookeeper/data && \
    chown -R hadoop:hadoop /opt

# Switch to hadoop user
USER hadoop
WORKDIR /home/hadoop

# Download and extract Hadoop
RUN curl -L https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | \
    tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop

# Download and extract ZooKeeper
RUN curl -L https://downloads.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz | \
    tar -xz -C /opt && \
    mv /opt/apache-zookeeper-${ZOOKEEPER_VERSION}-bin /opt/zookeeper && \
    cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg

# Configure environment
RUN echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.bashrc && \
    echo "export PATH=$PATH" >> ~/.bashrc && \
    echo "export HADOOP_CONF_DIR=$HADOOP_CONF_DIR" >> ~/.bashrc && \
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Copy configuration files
COPY --chown=hadoop:hadoop config/ $HADOOP_CONF_DIR/
COPY --chown=hadoop:hadoop zookeeper/conf/zoo.cfg $ZOOKEEPER_HOME/conf/

# Configure Hadoop environment
RUN echo "export HDFS_NAMENODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_DATANODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_SECONDARYNAMENODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_RESOURCEMANAGER_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_NODEMANAGER_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_JOURNALNODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_ZKFC_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
    echo "export HADOOP_LOG_DIR=/opt/hadoop/logs" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

# Ports exposure
EXPOSE 8020 9000 9870 8088 2181 2888 3888 8485 8019 9864

ENTRYPOINT ["/entrypoint.sh"]