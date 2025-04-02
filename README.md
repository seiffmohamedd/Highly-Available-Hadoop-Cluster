# Highly Available Hadoop Cluster with Docker

## Project Overview

This project involves setting up a **Highly Available Hadoop Cluster** manually and then automating the setup using Docker. The cluster consists of **3 Master Nodes** and **1 Worker Node**, ensuring high availability for both **HDFS** and **YARN**.

## Project Phases

### Part 1: Manual Setup

We manually set up a Hadoop cluster with **HDFS High Availability (HA) and YARN HA**. The services running on each node are:

#### Master Nodes (3)

- **Zookeeper Service**
- **HDFS Journal Node**
- **HDFS Namenode** (Only one active at a time)
- **YARN Resource Manager** (Only one active at a time)

#### Worker Node (1)

- **HDFS Datanode**
- **YARN Nodemanager**

#### Steps:

1. **Create 4 Ubuntu containers** within the same Docker network.
2. **Manually install and configure** all required services.
3. **Test automatic failover** for HDFS Namenode and YARN ResourceManager.
4. **Ingest data into HDFS** and run a MapReduce job.
5. **Scale the cluster horizontally** by adding a second worker node.

### Part 2: Docker Automation

After successfully setting up the cluster manually, we containerize it to simplify deployment.

#### Deliverables:

- **Dockerfile**: Builds a reusable image for both master and worker nodes.
- **Docker Compose file**: Defines the cluster setup, network, volumes, dependencies, and health checks.
- **Entrypoint script** (if needed) to handle startup processes.
- **Java MapReduce job** to execute inside the containerized cluster.

## Setup Instructions

### Manual Setup

1. Follow the command history (`setup_history.txt`) for step-by-step installation.
2. Verify cluster status via HDFS and YARN UIs.
3. Test automatic failover and MapReduce execution.

### Dockerized Setup

1. **Build the image**:
   ```bash
   docker build -t hadoop-cluster .
   ```
2. **Deploy the cluster using Docker Compose**:
   ```bash
   docker-compose up -d
   ```
3. **Check services**:
   ```bash
   docker ps
   ```
4. **Run a sample MapReduce job** inside the cluster.

## Bonus

- Setup a remote Docker client to control the cluster.
- Configure a multi-host cluster using **Docker Swarm**.

## Files Included

- `setup_history.txt` - Commands used for manual setup
- `Dockerfile` - Image definition
- `docker-compose.yml` - Cluster orchestration
- `entrypoint.sh` (if applicable) - Startup script
- `mapreduce-job.jar` - Sample Java MapReduce job

## Authors

- **Youssef Etman**
- **Ibrahim Elsadek**

