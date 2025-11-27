#!/bin/bash

# Hadoop Installation and Configuration Script for EC2
# Run this script as ubuntu user (or ec2-user for Amazon Linux)

set -e  # Exit on any error

echo "==========================================="
echo "Hadoop Installation Script"
echo "==========================================="

# Update system
echo "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Java
echo "Step 2: Installing Java..."
sudo apt install openjdk-11-jdk -y

echo "Java version:"
java -version

# Create hadoop user
echo "Step 3: Creating hadoop user..."
sudo adduser --disabled-password --gecos "" hadoop
echo "hadoop:hadoop" | sudo chpasswd
sudo usermod -aG sudo hadoop

# Setup SSH for hadoop user
echo "Step 4: Configuring SSH for hadoop user..."
sudo -u hadoop bash <<'EOF'
cd ~
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 640 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
EOF

# Download and install Hadoop
echo "Step 5: Downloading Hadoop..."
sudo -u hadoop bash <<'EOF'
cd ~
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xzf hadoop-3.3.6.tar.gz
mv hadoop-3.3.6 hadoop
rm hadoop-3.3.6.tar.gz
EOF

# Configure environment variables
echo "Step 6: Configuring environment variables..."
sudo -u hadoop bash <<'EOF'
cat >> ~/.bashrc <<'BASHRC'

# Hadoop Environment Variables
export HADOOP_HOME=/home/hadoop/hadoop
export HADOOP_INSTALL=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
BASHRC

source ~/.bashrc
EOF

# Configure hadoop-env.sh
echo "Step 7: Configuring hadoop-env.sh..."
sudo -u hadoop bash <<'EOF'
source ~/.bashrc
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
EOF

# Configure core-site.xml
echo "Step 8: Configuring core-site.xml..."
sudo -u hadoop bash <<'EOF'
source ~/.bashrc
cat > $HADOOP_HOME/etc/hadoop/core-site.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
XML
EOF

# Configure hdfs-site.xml
echo "Step 9: Configuring hdfs-site.xml..."
sudo -u hadoop bash <<'EOF'
source ~/.bashrc
cat > $HADOOP_HOME/etc/hadoop/hdfs-site.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///home/hadoop/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///home/hadoop/hadoop/data/datanode</value>
    </property>
</configuration>
XML
EOF

# Configure mapred-site.xml
echo "Step 10: Configuring mapred-site.xml..."
sudo -u hadoop bash <<'EOF'
source ~/.bashrc
cat > $HADOOP_HOME/etc/hadoop/mapred-site.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
XML
EOF

# Configure yarn-site.xml
echo "Step 11: Configuring yarn-site.xml..."
sudo -u hadoop bash <<'EOF'
source ~/.bashrc
cat > $HADOOP_HOME/etc/hadoop/yarn-site.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
XML
EOF

# Create data directories
echo "Step 12: Creating data directories..."
sudo -u hadoop bash <<'EOF'
mkdir -p ~/hadoop/data/namenode
mkdir -p ~/hadoop/data/datanode
EOF

# Format NameNode
echo "Step 13: Formatting NameNode..."
sudo -u hadoop bash <<'EOF'
source ~/.bashrc
hdfs namenode -format -force
EOF

echo "==========================================="
echo "Installation and Configuration Complete!"
echo "==========================================="
echo ""
echo "To start Hadoop services, run as hadoop user:"
echo "  su - hadoop"
echo "  start-dfs.sh"
echo "  start-yarn.sh"
echo ""
echo "To verify services are running:"
echo "  jps"
echo ""
echo "Access Web UIs:"
echo "  NameNode: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9870"
echo "  YARN ResourceManager: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8088"
echo ""
