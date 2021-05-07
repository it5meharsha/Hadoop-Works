#!/bin/bash
user() {
uid=`id -u`
if [ $uid -eq "0" ]; then
echo " "
else
exit 
fi
}
#coded by it5meharsha

echo -n "Enter new group for hadoop user:"
read hdgroup
echo -n "Enter username for hadoop user:"
read hduser
echo "Adding user to group"
sudo addgroup $hdgroup
sudo adduser -ingroup $hdgroup $hduser
sleep 10
echo "$hdgroup is created and $hduser is assigned to the group"


updates_check() {
echo "checking for updates please wait..."
sudo apt-get update && apt-get upgrade -y && apt-get install ssh
}

java_version_check() {
echo "Checking for supported java version please wait..."
java_version=$(java -version 2>&1 > /dev/nul | grep version | awk '{print substr($3,4, length($3)-9);}'| tr -d ".")

if [ $java_version -eq "8" ];then
	echo "system has 8 installed and supported for hadoop"
	java_home=$(which java)
	path=$(readlink -f $java_home | cut -c 1-33)
	echo $path
	
else
	java_installation_check
fi
}

java_installation_check() {
sudo apt-get remove java-common
echo "please wait.."
sudo apt install openjdk-8-jdk -y
java_version_check
}

ssh_keys_creation(){
sudo -u $hduser ssh-keygen -t rsa -P ""
sudo -u $hduser cat /home/$hduser/.ssh/id_rsa.pub >> /home/$hduser/.ssh/authorized_keys
sleep 10
echo "ssh Keys created"
}

hd_install() {
download() {
                wget http://archive.apache.org/dist/hadoop/core/hadoop-3.3.0/hadoop-3.3.0.tar.gz
		#you can change the above url if you need anyother hadoop version 
                sleep 2
                tar xvfz hadoop-3.3.0.tar.gz
		#change the hadoop version to the version your downloading 
                sleep 2
                mv hadoop-3.3.0 /home/$hduser/hadoop
}
	if [ -f "/home/$hduser/hadoop-3.3.0.tar.gz" ]; then
	echo "Download Already exists... using the existing......."
	sleep 2
	tar xvfz hadoop-3.3.0.tar.gz
	sleep 5
	echo "Existing Dir deleted..."
	rm -rf /home/$hduser/hadoop
	sleep 5
	mv hadoop-3.3.0 /home/$hduser/hadoop
else
download
fi 

chown -R $hduser:$hdgroup /home/$hduser/hadoop
#tmp folder for furthur process
sudo -u $hduser mkdir -p /home/$hduser/hadoop/app/hadoop/tmp
sudo -u $hduser chown -R $hduser:$hdgroup /home/$hduser/hadoop/app/hadoop/tmp
#namenode and datanode
sudo -u $hduser mkdir -p /home/$hduser/hadoop/hadoop_store/hdfs/namenode
sudo -u $hduser mkdir -p /home/$hduser/hadoop/hadoop_store/hdfs/datanode
#changing owner to name and data node
sudo -u $hduser chown -R $hduser:$hdgroup /home/$hduser/hadoop/hadoop_store

#permission to .bashrc,hadoop-env.sh,core-site.xml,mapred.site.xml,hdfs-site.xml,yarn-site.xml

sudo -u $hduser chmod o+w /home/$hduser/.bashrc
sudo -u $hduser chmod o+w /home/$hduser/hadoop/etc/hadoop/hadoop-env.sh
sudo -u $hduser chmod o+w /home/$hduser/hadoop/etc/hadoop/core-site.xml
sudo -u $hduser chmod o+w /home/$hduser/hadoop/etc/hadoop/mapred-site.xml
sudo -u $hduser chmod o+w /home/$hduser/hadoop/etc/hadoop/hdfs-site.xml
sudo -u $hduser chmod o+w /home/$hduser/hadoop/etc/hadoop/yarn-site.xml


echo "export JAVA_HOME=$path" >> /home/$hduser/hadoop/etc/hadoop/hadoop-env.sh

#bashrc
echo -e '\n\n #Hadoop Variable START \n export HADOOP_HOME=/home/'$hduser'/hadoop \n export HADOOP_INSTALL=$HADOOP_HOME \n export HADOOP_MAPRED_HOME=$HADOOP_HOME \n export HADOOP_COMMON_HOME=$HADOOP_HOME \n export HADOOP_HDFS_HOME=$HADOOP_HOME \n export YARN_HOME=$HADOOP_HOME \n export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native \n export PATH=$PATH:$HADOOP_HOME/sbin/:$HADOOP_HOME/bin \n export HADOOP_OPTS=-Djava.library.path=$HADOOP_HOME/lib/native \n #Hadoop Variable END\n\n' >> /home/$hduser/.bashrc
source /home/$hduser/.bashrc

#core-site.xml
sudo sed -i '/<configuration>/a <property>\n\t\t<name>hadoop.tmp.dir</name>\n\t\t<value>/home/'$hduser'/hadoop/app/hadoop/tmp</value>\n</property>\n<property>\n\t\t<name>fs.default.name</name>\n\t\t<value>hdfs://localhost:9000</value>\n</property>' /home/$hduser/hadoop/etc/hadoop/core-site.xml

#mapred-site.xml
sudo sed -i '/<configuration>/a <property>\n\t\t <name>mapreduce.framework.name</name>\n\t\t <value>yarn</value>\n</property>' /home/$hduser/hadoop/etc/hadoop/mapred-site.xml

#hdfs-site.xml
sudo sed -i '/<configuration>/a <property>\n\t\t<name>dfs.data.dir</name>\n\t\t<value>/home/'$hduser'/hadoop/dfsdata/namenode</value>\n</property>\n<property>\n\t\t<name>dfs.data.dir</name>\n\t\t<value>/home/'$hduser'/hadoop/dfsdata/datanode</value>\n</property>\n\t\t<property><name>dfs.replication</name>\n\t\t<value>1</value>\n</property>' /home/$hduser/hadoop/etc/hadoop/hdfs-site.xml

#yarn-site.xml
sudo sed -i '/<configuration>/a <property>\n\t\t<name>yarn.nodemanager.aux-services</name>\n\t\t<value>mapreduce_shuffle</value>\n</property>\n<property>\n\t\t<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>\n\t\t<value>org.apache.hadoop.mapred.ShuffleHandler</value>\n</property>\n\t\t<property><name>yarn.resourcemanager.hostname</name>\n\t\t<value>127.0.0.1</value>\n</property>\n\t\t<property>\n\t\t<name>yarn.acl.enable</name>\n\t\t<value>0</value>\n</property>\n\t\t<property>\n\t\t<name>yarn.nodemanager.env-whitelist</name>\n\t\t<value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PERPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>\n</property>' /home/$hduser/hadoop/etc/hadoop/yarn-site.xml




#revoking permissions
sudo -u $hduser chmod o-w /home/$hduser/hadoop/etc/hadoop/hadoop-env.sh
sudo -u $hduser chmod o-w /home/$hduser/hadoop/etc/hadoop/core-site.xml
sudo -u $hduser chmod o-w /home/$hduser/hadoop/etc/hadoop/mapred-site.xml
sudo -u $hduser chmod o-w /home/$hduser/hadoop/etc/hadoop/hdfs-site.xml
sudo -u $hduser chmod o-w /home/$hduser/hadoop/etc/hadoop/yarn-site.xml

#hadoop dir
sudo ls /home/$hduser/hadoop

#ssh
sudo -u hduser ssh localhost
}


user
updates_check
java_version_check
ssh_keys_creation
hd_install

#you can comment the above 5 functions and make them independent each other (Example:if your already upto supported java version you can comment the java function (#java_Version_check)
#this will save your time 

