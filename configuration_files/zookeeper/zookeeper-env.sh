export JAVA_HOME=/usr/java/default
export ZOOKEEPER_HOME=/usr/hdp/current/zookeeper-server
export ZOOKEEPER_LOG_DIR=/var/log/zookeeper
export ZOOKEEPER_PID_DIR=/var/run/zookeeper/zookeeper_server.pid
export SERVER_JVMFLAGS=-Xmx1024m
export JAVA=$JAVA_HOME/bin/java
CLASSPATH=$CLASSPATH:$ZOOKEEPER_HOME/*