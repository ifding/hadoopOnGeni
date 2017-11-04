#!/bin/sh

#
# Directories Script
#
# 1. To use this script, you must edit the TODO variables below for your environment.
#
# 2. Warning: Leave the other parameters as the default values. Changing these default values will require you to
#    change values in other configuration files.
#

#
# Hadoop Service - HDFS
#

# Space separated list of directories where NameNode will store file system image.
DFS_NAME_DIR="/hdp/hdfs/nn" ;

# Space separated list of directories where DataNodes will store the blocks.
DFS_DATA_DIR="/hdp/hdfs/dn" ;

# Space separated list of directories where SecondaryNameNode will store checkpoint image.
FS_CHECKPOINT_DIR="/hdp/hdfs/snn" ;

# Directory to store the Hadoop configuration files.
HADOOP_CONF_DIR="/etc/hadoop/conf" ;

# Directory to store the HDFS logs.
HDFS_LOG_DIR="/var/log/hadoop/hdfs" ;

# Directory to store the HDFS process ID.
HDFS_PID_DIR="/var/run/hadoop/hdfs" ;

#
# Hadoop Service - YARN 
#

# Space separated list of directories where YARN will store temporary data.
YARN_LOCAL_DIR="/hdp/yarn/temp" ;

# Directory to store the YARN logs.
YARN_LOG_DIR="/var/log/hadoop/yarn" ; 

# Directory to store the YARN process ID.
YARN_PID_DIR="/var/run/hadoop/yarn" ;

# Create Directories
# ==================

# NameNode directories
mkdir -p $DFS_NAME_DIR;
chown -R $HDFS_USER:$HADOOP_GROUP $DFS_NAME_DIR;
chmod -R 755 $DFS_NAME_DIR;

# SNN directories
mkdir -p $FS_CHECKPOINT_DIR;
chown -R $HDFS_USER:$HADOOP_GROUP $FS_CHECKPOINT_DIR;
chmod -R 755 $FS_CHECKPOINT_DIR;

# Datanode and YARN NodeManager directories
mkdir -p $DFS_DATA_DIR;
chown -R $HDFS_USER:$HADOOP_GROUP $DFS_DATA_DIR;
chmod -R 750 $DFS_DATA_DIR;

mkdir -p $YARN_LOCAL_DIR;
chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOCAL_DIR;
chmod -R 755 $YARN_LOCAL_DIR;

# Log dirs

mkdir -p $YARN_LOG_DIR;
chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOG_DIR;
chmod -R 755 $YARN_LOG_DIR;

mkdir -p $YARN_PID_DIR;
chown -R $YARN_USER:$HADOOP_GROUP $YARN_PID_DIR;
chmod -R 755 $YARN_PID_DIR;

mkdir -p $MAPRED_LOG_DIR;
chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_LOG_DIR;
chmod -R 755 $MAPRED_LOG_DIR;
