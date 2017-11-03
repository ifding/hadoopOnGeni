#!/bin/bash

wget https://github.com/ifding/hadoopOnGeni/archive/master.zip -O hadoopOnGeni.zip -P /tmp
unzip -d hadoopOnGeni.zip -d /tmp
rm /tmp/hadoopOnGeni.zip
rm /tmp/download.sh
