#!/bin/bash

wget https://github.com/ifding/hadoopOnGeni/archive/master.zip -O hadoopOnGeni.zip
unzip hadoopOnGeni.zip -d /tmp
mv /tmp/hadoopOnGeni-master/ /tmp/hadoopOnGeni
rm hadoopOnGeni.zip
