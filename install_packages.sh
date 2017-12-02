#!/bin/bash

# Download SMRT-analysis
wget https://pc7yea.bl3301.livefilestore.com/y4mOjUp71v-DlwFBiRSSUTWzBqCdYVpDPaEgKsSgtbhUu1k78aRSvOfrVBADr6dvtCPQ
zEkj7kuKfkDGr9bFU13aMMU9auea_jaXsa_Pxq3IwSSEGLXRKPCdphKGrCxyeDfRwNvyrh-u1MY6CUmTlR3uzDsOpX9xvoGse4spmU7hOyaORFZsIdpzTAeCvsly6Yx1RbIC
67r1qXxTP1OZy8WMg/smrtanalysis.tar.gz?download&psid=1 -P /tmp/

wget https://pc6pbg.bl3301.livefilestore.com/y4meHzIIL4wvVl0QNTNrrZL5z3ePgYbooZzmNjV60qCnqM5Z2b2rSWYxy_w8h9-uzdNFycvgXhiuzJcHC5Pt_YRE0pIzTepCr9uIGl0FKYsN60bf-qOb4FKwPOjzLfE0uxrZ7gNGkycKjbtOOpMYUDpDHJu8NVKxnwOU3K136mnKEi8mjd56pqTjS76Da_p1QNIP1kTEDoFeD1mHu6H6kenhw/basemods_spark_v3.zip?download&psid=1 -P /tmp/

cd /tmp
sudo mv smrtanalysis.tar.gz?download smrtanalysis.tar.gz
sudo mv basemods_spark_v3.zip\?download basemods_spark_v3.zip

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
sudo python get-pip.py
sudo pip install --upgrade protobuf 
sudo pip install numpy h5py paramiko pbcore py4j pyspark

#To preserve symbolic links in the tar.gz file, “-h” must be used when using tar command.
sudo tar -xhzvf /tmp/smrtanalysis.tar.gz -C /opt
sudo unzip basemods_spark_v3.zip -d /opt
sudo mv /opt/basemods_spark_v3 /opt/basemods_spark

cd /opt
sudo chmod +x basemods_spark/scripts/exec_sawriter.sh
sudo chmod +x basemods_spark/scripts/baxh5_operations.sh
sudo chmod +x basemods_spark/scripts/cmph5_operations.sh
sudo chmod +x basemods_spark/scripts/mods_operations.sh

sudo sed -i "s/\/home\/hadoop/\/opt/g" basemods_spark/parameters.conf




