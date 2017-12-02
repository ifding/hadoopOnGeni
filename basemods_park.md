[](#basemods-on-spark)basemods on spark
---------------------------------------

### [](#overview)Overview

the spark version of basemods pipeline in SMRT-Analysis (v2.3.0)

### [](#set-up-the-environment)Set up the environment

The OSs must be **Linux**.

1.  #### [](#hadoopspark)Hadoop/Spark

    Setting up an
    [Hadoop](http://hadoop.apache.org/)/[Spark](https://spark.apache.org/)
    cluster.

2.  #### [](#smrt-analysis)SMRT-Analysis

    For now, we are using SMRT-Analysis v2.3.0

    2.1 Download
    [smrtanalysis.tar.gz](https://1drv.ms/u/s!AgfGWBktzWTwgjc7p4vgxt15FPQE).

    2.2 Copy *smrtanalysis.tar.gz* to **each worker node** of your Spark
    cluster. Then decompress it to a desired directory.\

        # suppose you want to decompress smrtanalysis.tar.gz to /home/hadoop, 
        # using the following command: 
        tar -xhzvf smrtanalysis.tar.gz -C /home/hadoop

    \
     **Note**:

    (1). The decompressed location of smrtanalysis.tar.gz must be the
    same on all worker nodes. Don’t forget to set the variable
    *SMRT\_ANALYSIS\_HOME* in parameters.conf. (Suppose you have
    decompressed *smrtanalysis.tar.gz* to */home/hadoop* on all worker
    nodes, then you have to set
    *SMRT\_ANALYSIS\_HOME=/home/hadoop/smrtanalysis* in parameters.conf)

    (2). To preserve symbolic links in the *tar.gz* file, “*-h*” must be
    used when using *tar* command.

3.  #### [](#python-2x-and-required-python-libraries)Python 2.x and required Python libraries {#python-2x-and-required-python-libraries}

    If the OSs of nodes (both master and workers) in your cluster don’t
    have python 2.x installed, you should install it. Install *numpy*,
    *h5py*, *paramiko*, *pbcore* in your python environment. Install
    package *py4j*, *pyspark* in your python environment if you need to.

    Note that **Python 2.7.13** (or higher) is strongly recommended (not
    necessary) because of the bug described in [issue
    \#5](https://github.com/PengNi/basemods_spark/issues/5).

### [](#how-to-use-basemods_spark)How to use basemods\_spark

1.  #### [](#make-the-scripts-executable)make the scripts executable

    If the scripts in the code of basemods\_spark you download don’t
    have execute permissions, you should make them executable.

        chmod +x basemods_spark/scripts/exec_sawriter.sh

        chmod +x basemods_spark/scripts/baxh5_operations.sh

        chmod +x basemods_spark/scripts/cmph5_operations.sh

        chmod +x basemods_spark/scripts/mods_operations.sh

2.  #### [](#copy-your-data)copy your data

    Copy your data to the master node of your *Hadoop/Spark* cluster.

3.  #### [](#parameters-in-configure-file)parameters in configure file

    Set the parameters in configure file ‘parameters.conf’.

4.  #### [](#start-spark-and-use-spark-submit-to-run-the-pipeline)start Spark and use spark-submit to run the pipeline

    ​(1) start HDFS if you need to

        $HADOOP_HOME/sbin/start-dfs.sh

    ​(2) start Spark\

        $SPARK_HOME/sbin/start-all.sh

    ​(3) submit your job\

        $SPARK_HOME/bin/spark-submit basemods_spark_runner.py

