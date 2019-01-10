## Centos7.2 HBase环境快速搭建

### 1.环境背景 
硬件：Centos7.2 服务器12台
软件：java_1.7.0_79, hadoop-2.7.2, hbase-1.2.2, zookeeper-3.4.8

### 2.安装前服务器配置
hostnamectl set-hostname  master3
 其余节点操作一样，然后reboot，重启生效
（1）Masters上修改/etc/hosts，加入以下几句：
10.80.6.60   master1 
10.80.6.61   master2
10.80.6.62   master3
10.80.6.63   datanode1
10.80.6.64   datanode2
10.80.6.65   datanode3
10.80.6.66   datanode4
10.80.6.67   datanode5

然后同步到各个节点：
scp /etc/hosts Slave0:/etc/
scp /etc/hosts Zk0:/etc/
其余节点类似。
（2）各节点配置无密码连接 
        在Master上执行 ssh-keygen -t rsa,回车默认
然后把生成的公钥拷贝到拷贝到其余节点(含本节点)
ssh-copy-id -i ~/.ssh/id_rsa.pub user@server：
cd /root/.ssh/

### 3.安装jdk
下载jdk的tar.gz包，拷贝到各个节点，然后执行安装操作：
tar -zxvf  jdk-7u79-linux-x64.tar.gz
chown -R root:root /opt/jdk-7u79-linux-x64

### 4.安装zookeeper
Zookeeper集群安装在Zk上，首先在Zk0上安装好
tar -zxvf  zookeeper-3.4.8.tar.gz  -C /usr/
mv /usr/zookeeper-3.4.8 /usr/local/zookeeper
cd /usr/zookeeper/conf/
cp zoo_sample.cfg zoo.cfg
vi zoo.cfg  加入以下内容：
dataDir=/data/zookeeper/data
dataLogDir=/data/zookeeper/logs
server.0=Zk0:2888:3888
server.1=Zk1:2888:3888
server.2=Zk2:2888:3888
minSessionTimeout=10000
maxSessionTimeout=900000

然后拷贝到其余zk节点：
scp -r /usr/zookeeper/ Zk1:/usr/
scp -r /usr/zookeeper/ Zk2:/usr/

在Zk各节点上创建目录及id文件：
mkdir -p /data/zookeeper/data
mkdir -p /data/zookeeper/logs
vi /data/zookeeper/data/myid #创建myid文件，并编辑它，编辑的内容就是配置文件中server.后面跟着的号数。例如目前是在Zk0机器上，则在myid文件中写入0

### 5.安装hadoop
首先在Master上安装好
tar -zxvf z hadoop-2.7.2.tar.gz  -C /usr/local/
mv /usr/local/hadoop-2.7.2 /usr/local/hadoop
cd /usr/local/hadoop/etc/hadoop/
(1) vi hadoop-env.sh 添加如下：
export JAVA_HOME=/usr/java/jdk1.7.0_79

(2)vi core-site.xml
<configuration>
 		<property>
      	<name>fs.defaultFS</name>
        	<value>hdfs://mycluster</value>
    	</property>
    	<property>
        	<name>fs.trash.interval</name>
        	<value>1440</value>
    	</property>
<property>
        	<name>hadoop.tmp.dir</name>
        	<value>/home/hadoop/data/hadoop/tmp</value>
    	</property>
    	<property>
        	<name>io.file.buffer.size</name>
        	<value>131702</value>
    	</property>
    	<property>
       	<name>ha.zookeeper.quorum</name>
       	<value>Zk0:2181,Zk1:2181,Zk2:2181</value>
    	</property>
    	<property>
      	<name>dfs.ha.fencing.methods</name>
      	<value>sshfence</value>
    	</property>
    	<property>
      	<name>dfs.ha.fencing.ssh.private-key-files</name>
      	<value>/home/hadoop/.ssh/id_rsa</value>
    	</property>
    	</configuration>

(3)vi hdfs-site.xml
<configuration>
<property>
    <name>dfs.namenode.name.dir</name>
    <value>/data/hadoop/hdfs/name</value>
</property>
<property>
    <name>dfs.datanode.data.dir</name>
    <value>/data/hadoop/hdfs/data</value>
</property>
<property>
    <name>dfs.webhdfs.enabled</name>
    <value>true</value>
</property>
<property>
    <name>dfs.replication</name>
    <value>3</value>
</property>
<property>
    <name>dfs.blocksize</name>
    <value>64m</value>
</property>
<property>
    <name>dfs.datanode.du.reserved</name>
    <value>1073741824</value>
</property>
<property>
    <name>dfs.namenode.handler.count</name>
    <value>100</value>
</property>

<property>
    <name>dfs.permissions.enabled</name>
    <value>true</value>
</property>
<property>
 <name>dfs.namenode.acls.enabled</name>
 <value>true</value>
   </property>
   <property>
 <name>dfs.nameservices</name>
 <value>mycluster</value>
   </property>
<property>
 <name>dfs.ha.namenodes.mycluster</name>
 <value>nn1,nn2</value>
   </property>
   <property>        				  <name>dfs.namenode.rpc-address.mycluster.nn1</name>
 <value>Master:8020</value>
   </property>
   <property>
        <name>dfs.namenode.rpc-address.mycluster.nn2</name>
 <value>Zk0:8020</value>
</property>
<property>        		<name>dfs.namenode.http-address.mycluster.nn1</name>
 <value>Master:50070</value>
   </property>
   <property>
        <name>dfs.namenode.http-address.mycluster.nn2</name>
 <value>Zk0:50070</value>
   </property>
<property>
       <name>dfs.namenode.shared.edits.dir</name>        	<value>qjournal://Zk0:8485;Zk1:8485;Zk2:8485/mycluster</value>
</property>
   <property>
  	        <name>dfs.client.failover.proxy.provider.mycluster</name>        	<value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
   </property>
   <property>
<name>dfs.journalnode.edits.dir</name>
      <value>/home/hadoop/data/journal</value>
   </property>
   <property>
 	      <name>dfs.ha.automatic-failover.enabled</name>
<value>true</value>
   </property>
</configuration>
 

然后拷贝到各个Slave上：
scp -r /usr/local/hadoop/ Slave0:/usr/local/
scp -r /usr/local/hadoop/ Slave1:/usr/local/
scp -r /usr/local/hadoop/ Slave2:/usr/local/
               .......

再在Master上配置：vi /usr/local/hadoop/etc/hadoop/slaves 改	为以下内容
Slave0
Slave1
Slave2
Slave3
Slave4
Slave5
Slave6
Slave7

### 6.安装hbase
首先在Master上进行安装
tar -zxvf hbase-1.2.2-bin.tar.gz -C /usr/local/
mv /usr/local/hbase-1.2.2 /usr/local/hbase
cd /usr/local/hbase/conf/
(1)vi hbase-env.sh修改以下内容：
export JAVA_HOME=/usr/java/jdk1.7.0_79
export HBASE_MANAGES_ZK=false

(2)vi hbase-site.xml
<property>
        <name>hbase.rootdir</name>
        <value>hdfs://mycluster/hbase</value>
    </property>
    <property>
        <name>hbase.cluster.distributed</name>
        <value>true</value>
    </property>
    <property>
        <name>hbase.master.port</name>
        <value>60000</value>
    </property>
    <property>
        <name>hbase.master.info.port</name>
        <value>16010</value>
    </property>
    <property>
        <name>hbase.regionserver.info.port</name>
        <value>16030</value>
    </property>
    <property>
        <name>hbase.zookeeper.quorum</name>
        <value>Zk0,Zk1,Zk2</value>
    </property>

(3)vi regionservers
Slave0
Slave1
Slave2
Slave3
Slave4
Slave5
Slave6
Slave7
(4)vi backup-masters
Zk0
然后拷贝到其余节点：
scp -r /usr/local/hbase/ Slave0:/usr/local/
scp -r /usr/local/hbase/ Slave1:/usr/local/
scp -r /usr/local/hbase/ Slave2:/usr/local/
......

### 7.配置环境变量
在Master上 vi /etc/profile添加如下内容
#hadoop
export HADOOP_HOME=/usr/local/hadoop

#hbase
export HBASE_HOME=/usr/local/hbase

#java
export JAVA_HOME=/usr/java/jdk1.7.0_79
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$HBASE_HOME/lib

export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HBASE_HOME/bin:$ZOOKEEPER_HOME/bin

拷贝到其余Slave节点：
scp -r /etc/profile Slave0:/etc/
scp -r /etc/profile Slave1:/etc/
scp -r /etc/profile Slave2:/etc/
......

source /etc/profile 使之生效

### 8.启动hbase,检查安装
启动顺序： zookeeper --> hadoop --> hbase

在各个Zk节点启动zookeeper:
zkServer.sh start

启动hadoop: 
第一次启动时：
Master: 
hdfs zkfc -formatZK
hadoop-daemon.sh start journalnode    3台
hdfs namenode -format mycluster
将/srv/hadoop/namenode/current 拷贝另一个namenode上去
scp -r /srv/hadoop/namenode/current/    master2:/srv/hadoop/namenode/
start-dfs.sh（启动hadoop）
同步一次元数据: hdfs namenode -bootstrapStandby?
hadoop fs -ls / （启动之后，查看hdfs文件系统/目录）

在Master启动hbase:
start-hbase.sh

检查运行情况：
正常启动之后运行jps，在Master上应该有以下进程：
 NameNode
 DFSZKFailoverController
 JournalNode
 QuorumPeerMain 
 HMaster
Slave上应该有：
 HRegionServer
    DataNode
在各节点上运行hbase shell命令，可以在终端对hbase进行表操作

### 9.安装过程遇到的问题以及解决
(1) 在hbase启动时失败或启动一段时间后HMaster以及部分HRegionServer异常退出，查看日志文件错误为会话过时，或通过zookeeper找不到HMaster，这些情况下多半为集群内时间不同步导致的。
解决办法：利用ntp同步时间
步骤：
1）在Master上开启ntpd服务，同步本地时间源：
vi /etc/ntp.conf
修改以下内容
#restrict default nomodify notrap nopeer noquery （注释此句）
restrict 172.16.65.0 mask 255.255.255.0 nomodify notrap （允许	172.16.65网段的ip来同步此时间服务器）
加入以下内容
server 127.127.1.0 （本地时钟源）
fudge 127.127.1.0 stratum 4
开启ntpd服务，并设置开机启动
systemctl start ntpd
systemctl enable ntpd
2）在其余节点上使用ntpdate来同步Master的时间源，为使集群时间长时间保持在一定误差内，将同步时间动作加入到例行性工作排程，
vi /etc/crontab加入以下内容，
 */5  *  *  *  *  root   ntpdate 172.16.65.244 > /dev/null
上面语句代表每隔5分钟同步一次时间，重启服务生效
systemctl restart crond

(2)集群运行一段时间后更换用户运行，这种情况下一定要注意集群所涉及到的文件的用户权限，最好的办法是把这些文件的所属用户改为需运行的用户（在所有节点上都要），然后再启动集群服务。
(3)Datanode扩容磁盘
1、格式化磁盘带磁盘LABEL
   mkfs.xfs -f -L sdk /dev/sdk
   mkdir -p /srv/hadoop/data9
   mount -t xfs  -o defaults,nobarrier,noatime,nodiratime -L sdk /srv/hadoop/data9
echo “mount -t xfs  -o defaults,nobarrier,noatime,nodiratime -L sdk /srv/hadoop/data9”  >>  /opt/hadoop-2.7.5/sbin/mount-devices.sh
2、把/srv/hadoop/data9路径加入到hdfs-site.xml的dfs.datanode.data.dir配置项，最后在namenode上运行hdfs dfsadmin -reconfig datanode ip:50020 start，查询状态 dfsadmin -reconfig datanode HOST:PORT status
(4)Hadoop高可用
(5)Datanode更换故障的磁盘
   https://blog.csdn.net/zhangxin1988/article/details/55798648 

Hbase restserver部署
     1、修改/etc/hosts
[root@HP2-94 conf]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.80.6.60   master1 
10.80.6.61   master2
10.80.6.62   master3
10.80.6.63   datanode1
10.80.6.64   datanode2
10.80.6.65   datanode3
10.80.6.66   datanode4

     2、从10.80.6.212拷贝软件: /opt/hbase-1.2.6和  /opt/jdk1.7.0_80到本机/opt目录
     3、检查hbase-site.xml
<configuration>
<property>
    <name>hbase.zookeeper.quorum</name>
    <value>master1,master2,master3</value>
</property>
<property>
    <name>zookeeper.session.timeout</name>
    <value>360000</value>
</property>
<property>
    <name>hbase.regionserver.restart.on.zk.expire</name>
    <value>true</value>
</property>
<property>
    <name>hbase.client.write.buffer</name>
    <value>8388608</value>
</property>
</configuration>
  4  修改/etc/profile 
#hbase
export HBASE_HOME=/opt/hbase-1.2.6

#java
export JAVA_HOME=/opt/jdk1.7.0_80
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:$JAVA_HOME/jre/lib/rt.jar:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar:$HBASE_HOME/lib
export PATH=$PATH:$JAVA_HOME/bin:$HBASE_HOME/bin
  5、修改Linux系统参数，从10.60.6.63拷贝过来：
       /etc/sysctl.conf
         /etc/security/limits.conf 

    6、时间同步
[root@datanode2 conf]# crontab -l
#Ansible: time sync
@hourly /usr/sbin/ntpdate us.pool.ntp.org > /dev/null; /usr/sbin/clock -w





在线扩容一个数据节点datanodeN
1、软件安装 jdk /hadoop/ hbase，从datanode1上scp过来
2、磁盘格式化xfs和启动时挂载脚本(/opt/hadoop-2.7.5/sbin/mount-devices.sh)
3、修改/etc/hosts, 各master、datanode和rest server节点都需要增加datanodeN。
4、修改Linux系统参数，从datanode1上scp过来
       /etc/sysctl.conf
         /etc/security/limits.conf 
         /etc/rc.local           (服务器启动后自动挂载磁盘)
         chmod +x /etc/rc.d/rc.local
         /etc/profile   (JAVA HADOOP HBASE环境变量)
5、hdfs的操作
     修改主节点/opt/hadoop-2.7.5/etc/hadoop/slaves文件，添加新增节点的hostname信息（集群重启时使用），scp到其他节点
    sbin/hadoop-daemon.sh start datanode
6、hbase的操作
     修改主节点/opt/hbase-1.2.6/conf/regionservers文件，添加新增节点的hostname信息（集群重启时使用），scp到其他节点
      hbase-daemon.sh start regionserver


7、时间同步



Truncate 大表会出现超时导致数据不一致，hbase启动失败，修复方法：
   1、停止master-》zk server
   1、删除hdfs的/hbase目录
   2、清理zk上的znode /hbase/table无用的数据
   


   hbase(main):005:0* balancer_enabled
   hbase(main):006:0> balance_switch false





move '1588230740', 'datanode5,16020,1525930142615'

datanode5,16020,1525930142615
move '1588230740', 'datanode1,16020,1525814677907'