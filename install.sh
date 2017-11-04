#!/bin/bash

#software requirements
sudo yum -y update
sudo yum install -y scp
sudo yum install -y curl
sudo yum install -y tar
sudo yum install -y unzip
sudo yum install -y wget
sudo yum install -y ntp

source setup.properies

cd /tmp/

#download java package
wget --no-cookies \
--no-check-certificate \
--header "Cookie: oraclelicense=accept-securebackup-cookie" \
$java_repo_location -O jdk-8-linux-x64.tar.gz

#set up repository
wget -nv $hdp_repo_location -O /etc/yum.repos.d/hdp.repo

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

#install zookeeper
sudo yum install -y zookeeper-server

#install hadoop core packages from yum
sudo yum install -y hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce hadoop-client openssl

