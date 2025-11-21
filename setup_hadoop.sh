#!/bin/bash

set -e

echo "=============================="
echo " Updating Ubuntu"
echo "=============================="
sudo apt update -y
sudo apt upgrade -y

echo "=============================="
echo " Installing Java (OpenJDK 11)"
echo "=============================="
sudo apt install -y openjdk-11-jdk

JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
echo "Java installed at: $JAVA_HOME"

echo "=============================="
echo " Creating Hadoop User"
echo "=============================="
sudo adduser --disabled-password --gecos "" hadoopuser || true
echo "hadoopuser ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/hadoopuser

sudo -u hadoopuser bash << 'EOF'

echo "=============================="
echo " Downloading Hadoop 3.3.6"
echo "=============================="
cd ~

wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xvf hadoop-3.3.6.tar.gz
mv hadoop-3.3.6 hadoop

echo "=============================="
echo " Setting Environment Variables"
echo "=============================="
cat <<EOT >> ~/.bashrc

# Hadoop Environment
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
export HADOOP_HOME=/home/hadoopuser/hadoop
export HADOOP_INSTALL=/home/hadoopuser/hadoop
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
EOT

source ~/.bashrc

echo "=============================="
echo " Configuring Hadoop XML Files"
echo "=============================="

# CORE-SITE.XML
cat <<EOT > ~/hadoop/etc/hadoop/core-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOT

# HDFS-SITE.XML
cat <<EOT > ~/hadoop/etc/hadoop/hdfs-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOT

# MAPRED-SITE.XML
cat <<EOT > ~/hadoop/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOT

# YARN-SITE.XML
cat <<EOT > ~/hadoop/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOT

echo "=============================="
echo " Formatting Hadoop Namenode"
echo "=============================="
~/hadoop/bin/hdfs namenode -format

echo "=============================="
echo " Hadoop Installation Complete!"
echo " Log in as hadoopuser to start Hadoop:"
echo "     su - hadoopuser"
echo " To start Hadoop:"
echo "     start-dfs.sh"
echo "     start-yarn.sh"
echo "=============================="

EOF

echo "DONE!"
