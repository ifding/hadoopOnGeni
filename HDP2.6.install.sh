#!/usr/bin/bash 

# The Initial setup is described here: https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.1.0/bk_ambari-installation/content/ch_Getting_Ready.html
# The install procedure is described here: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_command-line-installation/bk_command-line-installation.pdf

fqdn_hostname=`hostname -f`

function setup_password_less_ssh { 
	if [ ! -f /root/.ssh/id_rsa ]; then
		echo "Need to set ssh keys. Running ssh-keygen. Please follow the instructions"
		ssh-keygen
	fi

	cd /root/.ssh
	cat id_rsa.pub >> authorized_keys
	chmod 700 ~/.ssh
	chmod 600 ~/.ssh/authorized_keys
	
	echo "Testing that setup password-less ssh done correctly"
	echo "please reply 'yes' if asked: Are you sure you want to continue connecting (yes/no)? "
	echo "If you are asked to enter a password, it means that something went wrong while setting up. Please resolve manually."
	reply=`ssh $fqdn_hostname date`

}

function prepare_the_environment {
	
	yum install -y ntp
	systemctl enable ntpd
	systemctl start ntpd	
	
	systemctl disable firewalld
	service firewalld stop
	
	setenforce 0
	
	umask 0022
	
}


function ambari_install {
	echo "INFO: ambari_install: "
	echo "This section downloads the required packages to run ambari-server."
	
	wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.6.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
	yum repolist
	
	yum install -y ambari-server 
	
}

function ambari_config_start {
	echo "INFO: ambari_config_start:"
	echo "Please accept all defaults proposed while in the following steps configuring the server. "
	echo "If required, Detailed explanation and instructions for configuring ambari-server at:" 
	echo "https://docs.hortonworks.com/HDPDocuments/Ambari-2.6.1.0/bk_ambari-installation/content/set_up_the_ambari_server.html "
	
	ambari-server setup
	ambari-server start
} 

function fetch_hdp_manual_install_rpm_helper_files {
	cd /tmp
	wget http://public-repo-1.hortonworks.com/HDP/tools/2.6.0.3/hdp_manual_install_rpm_helper_files-2.6.0.3.8.tar.gz
	tar zxvf hdp_manual_install_rpm_helper_files-2.6.0.3.8.tar.gz
	
	PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES=/tmp/hdp_manual_install_rpm_helper_files-2.6.0.3.8
	
}


function users_and_groups() { 
	# Comments: 
	#	1. users created below with hardcoded values - TODO use the variables properly - low priority 
	#	2. missing users from this procedure: pig
	#	3. Seems that there are some users that are not really needed for the purpose of this one node cluster. TODO: review again - low priority

	cd $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES
	
	.  scripts/usersAndGroups.sh
	
	# Create the required groups 

	groupadd  $HADOOP_GROUP
	groupadd  mapred
	groupadd  nagios

	useradd -G $HADOOP_GROUP			$HDFS_USER
	useradd -G $HADOOP_GROUP			$YARN_USER

	# The install doc  lists mapred differently.  
	# TODO: review in low priority - the way written in the install doc does not work properly. this fix seems to work fine.
	useradd -G $HADOOP_GROUP 			$MAPRED_USER
	useradd -G $HADOOP_GROUP			$HIVE_USER
	useradd -G $HADOOP_GROUP			$WEBHCAT_USER
	useradd -G $HADOOP_GROUP			$HBASE_USER
	# TODO: Need to find out if I need the following users that created without using variable  
	useradd -G $HADOOP_GROUP			falcon
	useradd -G $HADOOP_GROUP			sqoop
	useradd -G $HADOOP_GROUP			$ZOOKEEPER_USER
	useradd -G $HADOOP_GROUP			$OOZIE_USER
	useradd -G $HADOOP_GROUP			knox
	useradd -G nagios			nagios
}


# Not sure what is the diff between the two instructions set. Need to review once again. 

# https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_command-line-installation/content/ch_getting_ready_chapter.html
# https://cwiki.apache.org/confluence/display/AMBARI/Installation+Guide+for+Ambari+2.6.1

function set_environment() {
	# This page describes the environment variables that need to be set: 
	# https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_command-line-installation/content/def-environment-parameters.html

	cd $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES/scripts
	
	
	sed directories.sh -i.ORIG 	-e "s=TODO-LIST-OF-NAMENODE-DIRS=/hadoop/hdfs/namenode=
					    s=TODO-LIST-OF-DATA-DIRS=/hadoop/hdfs/data=
					    s=TODO-LIST-OF-SECONDARY-NAMENODE-DIRS=/hadoop/hdfs/namesecondary=
					    s=TODO-LIST-OF-YARN-LOCAL-DIRS=/hadoop/yarn/local=	
					    s=TODO-LIST-OF-YARN-LOCAL-LOG-DIRS=/hadoop/yarn/log=
					    s=TODO-ZOOKEEPER-DATA-DIR=/hadoop/zookeeper="

# TODO - local backup. Be sure to remove from final version
#	sed directories.sh -i.ORIG 	-e "s/TODO-LIST-OF-NAMENODE-DIRS/\/hadoop\/hdfs\/namenode/
#									s/TODO-LIST-OF-DATA-DIRS/\/hadoop\/hdfs\/data/
#									s/TODO-LIST-OF-SECONDARY-NAMENODE-DIRS/\/hadoop\/hdfs\/namesecondary/
#									s/TODO-LIST-OF-YARN-LOCAL-DIRS/\/hadoop\/yarn\/local/	
#									s/TODO-LIST-OF-YARN-LOCAL-LOG-DIRS/\/hadoop\/yarn\/log/
#									s/TODO-ZOOKEEPER-DATA-DIR/\/hadoop\/zookeeper/   "
#

	. $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES/scripts/directories.sh
	
}



function install_haddop_core {
	cd
	umask 0022
	wget -nv http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.6.3.0/hdp.repo -O /etc/yum.repos.d/hdp.repo
	yum repolist
	
	yum install -y hadoop hadoop-hdfs hadoop-libhdfs hadoop-yarn hadoop-mapreduce hadoop-client openssl
	yum install -y snappy snappy-devel
	yum install -y lzo lzo-devel hadooplzo hadooplzo-native

	# Create the NameNode Directories
	mkdir -p $DFS_NAME_DIR;
	chown -R $HDFS_USER:$HADOOP_GROUP $DFS_NAME_DIR;
	chmod -R 755 $DFS_NAME_DIR;
	

	# Create the SecondaryNameNode Directories 
	# TODO: Not sure this is required - low priority

	mkdir -p $FS_CHECKPOINT_DIR;
	chown -R $HDFS_USER:$HADOOP_GROUP $FS_CHECKPOINT_DIR; 
	chmod -R 755 $FS_CHECKPOINT_DIR;	

	# Create DataNode and YARN NodeManager Local Directories
	mkdir -p $DFS_DATA_DIR;
	chown -R $HDFS_USER:$HADOOP_GROUP $DFS_DATA_DIR;
	chmod -R 750 $DFS_DATA_DIR;

	mkdir -p $YARN_LOCAL_DIR;
	chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOCAL_DIR;
	chmod -R 755 $YARN_LOCAL_DIR;

	mkdir -p $YARN_LOCAL_LOG_DIR;
	chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOCAL_LOG_DIR; 
	chmod -R 755 $YARN_LOCAL_LOG_DIR;

	# Create the Log and PID Directories
	mkdir -p $HDFS_LOG_DIR;
	chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_LOG_DIR;
	chmod -R 755 $HDFS_LOG_DIR;

	mkdir -p $YARN_LOG_DIR; 
	chown -R $YARN_USER:$HADOOP_GROUP $YARN_LOG_DIR;
	chmod -R 755 $YARN_LOG_DIR;

	mkdir -p $HDFS_PID_DIR;
	chown -R $HDFS_USER:$HADOOP_GROUP $HDFS_PID_DIR;
	chmod -R 755 $HDFS_PID_DIR;

	mkdir -p $YARN_PID_DIR;
	chown -R $YARN_USER:$HADOOP_GROUP $YARN_PID_DIR;
	chmod -R 755 $YARN_PID_DIR;

	mkdir -p $MAPRED_LOG_DIR;
	chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_LOG_DIR;
	chmod -R 755 $MAPRED_LOG_DIR;

	mkdir -p $MAPRED_PID_DIR;
	chown -R $MAPRED_USER:$HADOOP_GROUP $MAPRED_PID_DIR;
	chmod -R 755 $MAPRED_PID_DIR;


	#TODO: Pg 46:  using hdp-select failed. think that is not important in this context. 
	
}



function setup_hadoop_config {
	# This function revises the config template files. The original template file is saved with the suffix ".ORIG_HELPER".
	# The changes are according to Section 4 of the manual (Setting Up the Hadoop Configuration, pp. 48 - 53)

	# TODO: Test that nothing is left as "TODO". 
	
	
	cd $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES/configuration_files/core_hadoop
	
	sed core-site.xml -i.ORIG -e s/TODO-NAMENODE-HOSTNAME:PORT/${fqdn_hostname}:8020/ 
	 
	# Secondary Namenode is NOT a backup. The following blog describes its function: http://blog.madhukaraphatak.com/secondary-namenode---what-it-really-do/ 

	sed hdfs-site.xml  -i.ORIG_HELPER    -e  "s=TODO-DFS-DATA-DIR=file:///${DFS_DATA_DIR}=               ;
						  s=TODO-NAMENODE-HOSTNAME:50070=${fqdn_hostname}:50070=      ;
						  s=TODO-DFS-NAME-DIR=${DFS_NAME_DIR}=			;		
						  s=TODO-FS-CHECKPOINT-DIR=${FS_CHECKPOINT_DIR}=              ; 
						  s=TODO-SECONDARYNAMENODE-HOSTNAME:50090=${fqdn_hostname}:50090="
	
	sed yarn-site.xml -i.ORIG_HELPER -e "s=TODO-YARN-LOCAL-DIR=$YARN_LOCAL_DIR=                   ;
	                              	     s/TODO-RMNODE-HOSTNAME:19888/${fqdn_hostname}:19888/     ;
	                              	     s/TODO-RMNODE-HOSTNAME:8141/${fqdn_hostname}:8141/	      ;
	                                     s=TODO-YARN-LOCAL-LOG-DIR=$YARN_LOCAL_LOG_DIR=           ;
	                                     s/TODO-RMNODE-HOSTNAME:8025/${fqdn_hostname}:8025/	      ;
	                                     s/TODO-RMNODE-HOSTNAME:8088/${fqdn_hostname}:8088/	      ;								
	                                     s/TODO-RMNODE-HOSTNAME:8050/${fqdn_hostname}:8050/	      ;
	                                     s/TODO-RMNODE-HOSTNAME:8030/${fqdn_hostname}:8030/       "
							
	# TODO: Don't know what to do with this comment (Page 49):
	# The maximum value of the NameNode new generation size (- XX:MaxnewSize ) should be 1/8 of the maximum heap size (-Xmx). 
	# Ensure that you check the default setting for your environment.


	sed mapred-site.xml -i.ORIG_HELPER -e "s/TODO-JOBHISTORYNODE-HOSTNAME:10020/${fqdn_hostname}:10020/
	                                s/TODO-JOBHISTORYNODE-HOSTNAME:19888/${fqdn_hostname}:19888/	"


	touch $HADOOP_CONF_DIR/dfs.exclude
	JAVA_HOME=/usr/java/default
	
	echo "### Settings for Haddop " >> /etc/profile
	echo "export JAVA_HOME=$JAVA_HOME"  >> /etc/profile
	echo "export HADOOP_CONF_DIR=$HADOOP_CONF_DIR" 	>> /etc/profile
	echo "export PATH=\$PATH:\$JAVA_HOME:\$HADOOP_CONF_DIR	" 	>> /etc/profile
	echo "###" 	>> /etc/profile
	
	# skipped optional step: Optional: Configure MapReduce to use Snappy Compression. (pg 51)
	# Skipped optional step: Optional: If you are using the LinuxContainerExecutor ... 

	# TODO - bullet 6 -  memory configuration settings
	
#	#The instructions (bullet 7) propose to wipe out $HADOOP_CONF_DIR and create it again using the "helper files" from above. 
#	#Seems better to retain the original as it includes the tags descriptions in addition to the value. 
#       
#	cd $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES/configuration_files/core_hadoop/
#        	
#	files_to_copy=$(ls *.ORIG_HELPER)
#	for file in $files_to_copy
#	do
#	   file_no_suffix=${file%".ORIG_HELPER"}
#	   cmd="cp -p $file_no_suffix $HADOOP_CONF_DIR"
#	   echo "$cmd "
#	   eval $cmd
#	done
#	
#	cp -p *.ORIG_HELPER $HADOOP_CONF_DIR

	cp -fr $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES/configuration_files/core_hadoop/*  $HADOOP_CONF_DIR

	
	cd $HADOOP_CONF_DIR
	chown -R $HDFS_USER:$HADOOP_GROUP $HADOOP_CONF_DIR/../
	chmod -R 755 $HADOOP_CONF_DIR/../

	sed $HADOOP_CONF_DIR/hadoop-env.sh -i.old -e "s/#export JAVA_HOME=\${JAVA_HOME}/export JAVA_HOME=\${JAVA_HOME}/"

	# TODO: I'm unhappy with the changes to /etc/profile. to verify if I can relay on $HADOOP_CONF_DIR/hadoop-env.sh instead !!! - high priority !!!

	
	# TODO: Sec 8 - not sure about the instruction. I guess need to edit $HADOOP_CONF_DIR/hadoop-env.sh
	# Currently, the parameter HADOOP_NAMENODE_OPTS is commented out. 
	# This looks like fine tunning that I can return to it back later. 
	
}

function validate_core_hadoop_installation {

    #if [ `stat -c %A /dev/null | sed 's/.....\(.\)..\(.\).\+/\1\2/'` != "ww" ] 
    #then
        # For some strange reason, /dev/null is not writeable to all. Someone probably regular file to /dev/null by mistake. 
        # So fix it ..
    #    rm /dev/null
    #    mknod /dev/null c 1 3
    #    chmod 666 /dev/null
    #fi

    #
    # Format and start HDFS
    #

    # Execute the following commands on the NameNode host machine:
    su -c -l $HDFS_USER "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/bin/hdfs namenode -format"
    su -c -l $HDFS_USER "/usr/hdp/current/hadoop-hdfs-namenode/../hadoop/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start namenode"

    # Execute the following commands on the SecondaryNameNode:
    su -c -l $HDFS_USER "/usr/hdp/current/hadoop-hdfs-secondarynamenode/../hadoop/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start secondarynamenode"

    # Execute the following commands on all DataNodes:
    su -c -l $HDFS_USER "/usr/hdp/current/hadoop-hdfs-datanode/../hadoop/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start datanode"


}

### yf stopped here: 20180117 - page 52 of: https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_command-line-installation/bk_command-line-installation.pdf 									





# Run it 

# TODO: Some functions removed for test purposes. Be sure to include them all!!!

#setup_password_less_ssh 
#prepare_the_environment 
#ambari_install 
#ambari_config_start 

fetch_hdp_manual_install_rpm_helper_files 
. $PATH_HDP_MANUAL_INSTALL_RPM_HELPER_FILES/scripts/usersAndGroups.sh
#users_and_groups    
set_environment
install_haddop_core 
setup_hadoop_config
validate_core_hadoop_installation 




  

####### MY SCARATCH AREA ##############################	

echo "# The end #" 

exit


ulimit -Sn
ulimit -Hn

# If the output is not greater than 10000, run the following command to set it to a suitable default:

ulimit -n 10000

hostname -f

# NTP: Sec 4.3 # https://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.0/bk_Installing_HDP_AMB/content/_enable_ntp_on_the_cluster_and_on_the_browser_host.html

systemctl is-enabled ntpd
systemctl enable ntpd
systemctl start ntpd

# set hostname to FQDN:  
#		hostname `hostname -f`

# Firewall - BE SURE TO PERFORM EVERY TIME AFTER REBOOT

systemctl disable firewalld
service firewalld stop

setenforce 0

####################

wget -nv http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.2.1.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
yum repolist
yum install ambari-server


ambari-server setup


ambari-server start

#To check the Ambari Server processes:
ambari-server status

#To stop the Ambari Server:
#ambari-server stop

echo "copy the URL below to your browser: "
echo "http://`hostname`:8080"

