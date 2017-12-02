#!/bin/bash

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
sudo python get-pip.py
sudo pip install --upgrade protobuf 
sudo pip install numpy h5py paramiko pbcore py4j pyspark

# All Worker Node
if ! [ "$(echo $(hostname) | cut -d. -f1)" = "namenode" ]; then
  # Download SMRT-analysis
  wget http://node.smrt.pdc-edu-lab-pg0.clemson.cloudlab.us/smrtanalysis.tar.gz -P /tmp/
  sudo tar -xhzvf /tmp/smrtanalysis.tar.gz -C /opt
fi


# Master Node
if [ "$(echo $(hostname) | cut -d. -f1)" = "namenode" ]; then
  wget http://node.smrt.pdc-edu-lab-pg0.clemson.cloudlab.us/basemods_spark_v3.zip -P /tmp/
  sudo unzip /tmp/basemods_spark_v3.zip -d /opt
  sudo mv /opt/basemods_spark_v3 /opt/basemods_spark
  cd /opt/basemods_spark
  sudo chmod +x scripts/exec_sawriter.sh
  sudo chmod +x scripts/baxh5_operations.sh
  sudo chmod +x scripts/cmph5_operations.sh
  sudo chmod +x scripts/mods_operations.sh
  sudo sed -i "s/\/home\/hadoop/\/opt/g" parameters.conf
 
  # Copy your data to the master node of your Hadoop/Spark cluster.
  # submit your job
  #$SPARK_HOME/bin/spark-submit basemods_spark_runner.py 
fi