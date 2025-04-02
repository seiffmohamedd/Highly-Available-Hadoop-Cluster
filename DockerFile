FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    HADOOP_VERSION=3.3.6 \
    ZOOKEEPER_VERSION=3.8.4 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    HADOOP_HOME=/opt/hadoop \
    ZOOKEEPER_HOME=/opt/zookeeper \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin:/opt/zookeeper/bin


RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    openssh-server \
    sshpass \
    rsync \
    curl \
    nano \
    wget \
    net-tools \
    vim \
    iputils-ping \
    netcat \
    python3 \
    procps \
    && rm -rf /var/lib/apt/lists/*



RUN useradd -ms /bin/bash hadoop && \
    mkdir -p /opt/hadoop /opt/zookeeper/data && \
    chown -R hadoop:hadoop /opt

# Step 3: Create users #update this in the script if this master1 then add user master1 , master2-> master2 and so on 
# RUN useradd -m master1 && \
#     useradd -m master2 && \
#     useradd -m master3 && \
#     useradd -m worker1

RUN mkdir -p /var/run/sshd && \
    ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N "" && \
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys && \
    chmod 777 /root/.ssh/authorized_keys && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config


USER hadoop
WORKDIR /home/hadoop

RUN curl -L https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | \
    tar -xz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop

RUN curl -L https://downloads.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz | \
    tar -xz -C /opt && \
    mv /opt/apache-zookeeper-${ZOOKEEPER_VERSION}-bin /opt/zookeeper && \
    cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg

RUN echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> ~/.bashrc && \
    echo "export PATH=$PATH" >> ~/.bashrc && \
    echo "export HADOOP_CONF_DIR=$HADOOP_CONF_DIR" >> ~/.bashrc && \
    ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN source ~/.bashrc

COPY --chown=hadoop:hadoop config/ $HADOOP_CONF_DIR/
COPY --chown=hadoop:hadoop zookeeper/conf/zoo.cfg $ZOOKEEPER_HOME/conf/

RUN echo "export HDFS_NAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_DATANODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_SECONDARYNAMENODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_RESOURCEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_NODEMANAGER_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_JOURNALNODE_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_ZKFC_USER=root" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
    echo "export HADOOP_LOG_DIR=/opt/hadoop/logs" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Copy configs and entrypoint
COPY MasterConfig/* /opt/hadoop/etc/hadoop/
COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh

EXPOSE 8020 9000 9870 8088 2181 2888 3888 8485 8019 9864

ENTRYPOINT ["/entrypoint.sh"]