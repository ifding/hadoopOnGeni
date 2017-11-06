#!/bin/bash

#get the hostname of NameNode
HDFS_HOSTNAME="$(hostname)"
shortname="$(echo $(hostname) | cut -d. -f1)"
replace="namenode"
HDFS_NAMENODE=${HDFS_HOSTNAME//$shortname/$replace}
HDFS_SECONDARY="$HDFS_NAMENODE"
YARN_RESOURCEMANAGER="$HDFS_NAMENODE"
ZOOKEEPER_QUORUM="$HDFS_NAMENODE"

#get the hostname of DataNode
if ! [ "${hostname#datanode}" = "${hostname}" ]; then
  echo "get datanode hostname";
  HDFS_DATANODE="$HDFS_HOSTNAME"
  YARN_NODEMANAGER="$HDFS_DATANODE"
fi


#software requirements
sudo yum -y update
sudo yum install -y scp
sudo yum install -y curl
sudo yum install -y tar
sudo yum install -y unzip
sudo yum install -y wget
sudo yum install -y ntp

source /tmp/hadoopOnGeni/setup.properies
cd /tmp/

#download java package
wget --no-cookies \
--no-check-certificate \
--header "Cookie: oraclelicense=accept-securebackup-cookie" \
$java_repo_location -O jdk-8-linux-x64.tar.gz

#set up repository
sudo wget -nv $hdp_repo_location -O /etc/yum.repos.d/hdp.repo

#set up java
sudo mkdir /usr/java && cd /usr/java
sudo tar -zxvf /tmp/jdk-8-linux-x64.tar.gz -C /usr/java
sudo rm /tmp/jdk-8-linux-x64.tar.gz
sudo mv /usr/java/jdk1.8.* /usr/java/jdk1.8
sudo ln -s /usr/java/jdk1.8 /usr/java/default
export JAVA_HOME=/usr/java/default
export PATH=$JAVA_HOME/bin:$PATH

echo $(hostname -f)

#prepare the environment
sudo su -c "systemctl enable ntpd; systemctl start ntpd"
sudo su -c "setenforce 0"
sudo su -c "systemctl stop firewalld; systemctl mask firewalld"

cd /tmp/hadoopOnGeni/
source scripts/directories.sh
source scripts/users.sh

#create hadoop group and system users
echo "Creating Hadoop group . . ."
groupadd $HADOOP_GROUP
echo "Creating Hadoop system accounts . . ."
useradd -g $HADOOP_GROUP $HDFS_USER
useradd -g $HADOOP_GROUP $MAPRED_USER
useradd -g $HADOOP_GROUP $TEMPLETON_USER
useradd -g $HADOOP_GROUP $ZOOKEEPER_USER
sleep 3


#install hadoop core packages from yum
sudo yum install -y hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce hadoop-client openssl

#NameNode directories
if ! [ "${hostname#namenode}" = "${hostname}" ]; then
  echo "creating namenode directories";
  sudo mkdir -p $DFS_NAME_DIR;
  sudo chown -R $HDFS_USER:$HADOOP_GROUP $DFS_NAME_DIR;
  sudo chmod -R 755 $DFS_NAME_DIR;
fi

#DataNode directories
if ! [ "${hostname#datanode}" = "${hostname}" ]; then
  echo "creating datanode directories";
  sudo mkdir -p $DFS_DATA_DIR;
  sudo chown -R $HDFS_USER:$HADOOP_GROUP $DFS_DATA_DIR;
  sudo chmod -R 750 $DFS_DATA_DIR;
fi

#All HDFS hosts
echo "All HDFS hosts"
sudo mkdir -p $HDFS_LOG_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_LOG_DIR
sudo chmod -R 755 $HDFS_LOG_DIR
sudo mkdir -p $HDFS_PID_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_PID_DIR
sudo chmod -R 755 $HDFS_PID_DIR

# All YARN hosts
echo "All YARN hosts"
sudo mkdir -p $YARN_LOG_DIR
sudo chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOG_DIR
sudo chmod -R 755 $YARN_LOG_DIR
sudo mkdir -p $YARN_PID_DIR
sudo chown -R $YARN_USER:$HADOOP_GROUP $YARN_PID_DIR
sudo chmod -R 755 $YARN_PID_DIR
sudo mkdir -p $YARN_LOCAL_DIR
sudo chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOCAL_DIR
sudo chmod -R 755 $YARN_LOCAL_DIR

# All YARN hosts MAPRED
sudo mkdir -p $MAPRED_LOG_DIR
sudo chown -R $YARN_USER:$HADOOP_GROUP $MAPRED_LOG_DIR
sudo chmod -R 755 $MAPRED_LOG_DIR

echo "Editing Hadoop core configuration files . . ."
cd /tmp/hadoopOnGeni/configuration_files/core_hadoop
sudo sed -i "s/TODO-NAMENODE-HOSTNAME/$HDFS_NAMENODE/g" ./core-site.xml
sudo sed -i 's;TODO-FS-CHECKPOINT-DIR;'"$FS_CHECKPOINT_DIR"';g' ./core-site.xml
sudo sed -i 's;TODO-DFS-NAME-DIR;'"$DFS_NAME_DIR"';g' ./hdfs-site.xml
sudo sed -i 's;TODO-DFS-DATA-DIR;'"$DFS_DATA_DIR"';g' ./hdfs-site.xml
sudo sed -i "s/TODO-NAMENODE-HOSTNAME/$HDFS_NAMENODE/g" ./hdfs-site.xml
sudo sed -i "s/TODO-SECONDARYNAMENODE-HOSTNAME/$HDFS_SECONDARY/g" ./hdfs-site.xml

# YARN
sudo sed -i "s/TODO-RMNODE-HOSTNAME/$YARN_RESOURCEMANAGER/g" ./yarn-site.xml
sudo sed -i 's;TODO-YARN-LOCAL-DIR;'"$YARN_LOCAL_DIR"';g' ./yarn-site.xml
sudo sed -i 's;TODO-YARN-LOG-DIR;'"$YARN_LOG_DIR"';g' ./yarn-site.xml

# MR v1 on YARN
sudo sed -i "s/TODO-RMNODE-HOSTNAME/$YARN_RESOURCEMANAGER/g" ./mapred-site.xml

sudo sed -i 's/-XX:NewSize=[0-9*m|G]*/-XX:NewSize=64m/g' ./hadoop-env.sh
sudo sed -i 's/-XX:MaxNewSize=[0-9*m|G]*/-XX:MaxNewSize=64m/g' ./hadoop-env.sh
sudo sed -i 's/-Xmx[0-9*m|G]*/-Xmx512m/g' ./hadoop-env.sh
sudo sed -i 's/-Xms[0-9*m|G]*/-Xms512m/g' ./hadoop-env.sh

# Workaround: NEED TO FIX THE BAD HEALTH CHECK: port 50060 instead of 8042
sudo sed -i "s/50060/8042/g" ./health_check

sudo echo "$HDFS_DATANODE" | tr ',' '\n' > "$HADOOP_CONF_DIR/slaves"

#All hosts
echo "Deploying Hadoop core configuration files . . ."
sudo rm -rf $HADOOP_CONF_DIR
sudo mkdir -p $HADOOP_CONF_DIR
sudo cp ./* $HADOOP_CONF_DIR
sudo chmod a+x $HADOOP_CONF_DIR
sudo chown -R $HDFS_USER:$HADOOP_GROUP $HADOOP_CONF_DIR/../
sudo chmod -R 755 $HADOOP_CONF_DIR/../

#workarounds
#All hosts
#sudo ln -s $HADOOP_LIB_DIR/libexec $YARN_LIB_DIR/
#sudo ln -s $HADOOP_LIB_DIR/libexec $MAPRED_LIB_DIR/
#TODO: HOW DO I SPECIFY THE LOG DIRECTION FOR MR ON YARN ???
# THIS SHOULD NOT BE NECESSARY
#sudo ln -s $MAPRED_LOG_DIR $MAPRED_LIB_DIR/logs

#Boot up HDFS
#NameNode
if ! [ "${hostname#namenode}" = "${hostname}" ]; then
  echo "namenode boot up HDFS";
  #formatting HDFS
  su hdfs -c "echo Y| hdfs namenode -format;
  #starting HDFS
  su hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start namenode;

  #creating base folders in HDFS
  su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hdfs";
  #su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp";
  #su hdfs -c "/usr/lib/hadoop/bin/hadoop fs -chmod +wt /tmp";
fi

#DataNode
if ! [ "${hostname#datanode}" = "${hostname}" ]; then
  echo "datanode starting HDFS";
  #starting HDFS
  su hdfs -c "/usr/lib/hadoop/sbin/hadoop-daemon.sh start datanode;
fi

#Boot up YARN
# All hosts
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /mapred/history/done_intermediate"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R 1777 /mapred/history/done_intermediate"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /mapred/history/done"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R 1777 /mapred/history/done"
# notice yarn owns this folder. MR will not work because of permissions otherwise (to verify)
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chown -R yarn /mapred"
# This is a workaround for MR1 on YARN. Remove or alter config.
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -mkdir -p /app-logs"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chown -R yarn /app-logs"
su $HDFS_USER -c "/usr/lib/hadoop/bin/hadoop fs -chmod -R +wt /app-logs"

#YARN_RESOURCEMANAGER
if ! [ "${hostname#namenode}" = "${hostname}" ]; then
  su yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh start resourcemanager"
  su yarn -c "/usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh start historyserver"
fi

#YARN_NODEMANAGER
if ! [ "${hostname#namenode}" = "${hostname}" ]; then
  su yarn -c "/usr/lib/hadoop-yarn/sbin/yarn-daemon.sh start nodemanager"
fi

#install ZooKeeper
sudo yum -y install zookeeper
echo "Creating ZooKeeper directories . . ."
sudo mkdir -p $ZOOKEEPER_LOG_DIR
sudo chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_LOG_DIR
sudo chmod -R 755 $ZOOKEEPER_LOG_DIR
sudo mkdir -p $ZOOKEEPER_PID_DIR
sudo chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_PID_DIR
sudo chmod -R 755 $ZOOKEEPER_PID_DIR
sudo mkdir -p $ZOOKEEPER_DATA_DIR
sudo chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_DATA_DIR
sudo chmod -R 755 $ZOOKEEPER_DATA_DIR

#ZooKeeper configuration
echo "Editing ZooKeeper configuration files . . ."
cd /tmp/hadoopOnGeni/configuration_files/zookeeper

sudo sed -i '/^dataDir/ c\dataDir='"$ZOOKEEPER_DATA_DIR"'' ./zoo.cfg

#ZOOKEEPER1=`echo ZOOKEEPER_QUORUM | tr ',' '\n' | sed -n '1 p'`
#ZOOKEEPER2=`echo ZOOKEEPER_QUORUM | tr ',' '\n' | sed -n '2 p'`
#ZOOKEEPER3=`echo ZOOKEEPER_QUORUM | tr ',' '\n' | sed -n '3 p'`

sudo sed -i "s/TODO-ZOOKEEPER-SERVER-1/$ZOOKEEPER1/g" ./zoo.cfg

#if [ "$ZOOKEEPER2" == "" ]; then
#    sudo sed -i '/TODO-ZOOKEEPER-SERVER-2/d' ./zoo.cfg;
#else
#    sudo sed -i "s/TODO-ZOOKEEPER-SERVER-2/$ZOOKEEPER2/g" ./zoo.cfg;
#fi
#if [ "$ZOOKEEPER3" == "" ]; then
#    sudo sed -i '/TODO-ZOOKEEPER-SERVER-3/d' ./zoo.cfg;
#else
#    sudo sed -i "s/TODO-ZOOKEEPER-SERVER-3/$ZOOKEEPER3/g" ./zoo.cfg;
#fi

echo "Deploying ZooKeeper configuration files . . ."
sudo rm -rf $ZOOKEEPER_CONF_DIR
sudo mkdir -p $ZOOKEEPER_CONF_DIR
sudo cp tmp/hadoopOnGeni/configuration_files/zookeeper/* $ZOOKEEPER_CONF_DIR
sudo chmod a+x $ZOOKEEPER_CONF_DIR/
sudo chown -R $ZOOKEEPER_USER:$HADOOP_GROUP $ZOOKEEPER_CONF_DIR/../
sudo chmod -R 755 $ZOOKEEPER_CONF_DIR/../

#install and configure startup scripts
