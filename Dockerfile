FROM centos:7
USER root

# os 기본툴 설치 & JAVA 설치
RUN yum -y update \
		&& yum install -y openssh-server openssh-clients \
		&& yum -y install vim net-tools zip wget \
		&& yum clean all

# 하둡 설치
RUN wget -O /hadoop.tar.gz http://apache.mirror.cdnetworks.com/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz \
        && tar xfz hadoop.tar.gz \
        && mv /hadoop-2.7.7 /usr/local/hadoop \
        && rm /hadoop.tar.gz

# 스파크 설치
RUN wget -O /spark.tar.gz http://apache.mirror.cdnetworks.com/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz \
		&& tar xfz spark.tar.gz \
		&& mv /spark-2.4.5-bin-hadoop2.7 /usr/local/spark \
		&& rm /spark.tar.gz

#scala 설치
RUN wget http://downloads.lightbend.com/scala/2.11.8/scala-2.11.8.rpm \
		&& yum install -y scala-2.11.8.rpm \
		&& yum clean all \
		&& rm scala-2.11.8.rpm

# java 설치 및 설정
RUN yum install -y java-1.8.0-openjdk-devel 
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# ssh 설정
RUN ssh-keygen -t rsa -f $HOME/.ssh/id_rsa -P "" \
		&& cat $HOME/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys

RUN sed -i 's/HostKey/\#HostKey/g' /etc/ssh/sshd_config \
		&& echo "HostKey ~/.ssh/id_rsa" >> /etc/ssh/sshd_config
		
# 하둡/스파크 설정
ENV HADOOP_HOME=/usr/local/hadoop
ENV SPARK_HOME=/usr/local/spark
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME:sbin

RUN mkdir -p $HADOOP_HOME/hdfs/namenode \
        && mkdir -p $HADOOP_HOME/hdfs/datanode

# 호스트에 있는 파일/디렉토리를 이미지에 추가
COPY config/ /tmp/

RUN mv /tmp/ssh_config $HOME/.ssh/config \
	&& mv /tmp/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh \
    && mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml \
    && mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml \
    && mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml.template \
    && cp $HADOOP_HOME/etc/hadoop/mapred-site.xml.template $HADOOP_HOME/etc/hadoop/mapred-site.xml \
    && mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml \
    && cp /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves \
    && mv /tmp/slaves $SPARK_HOME/conf/slaves \
    && mv /tmp/spark/spark-env.sh $SPARK_HOME/conf/spark-env.sh \
    && mv /tmp/spark/log4j.properties $SPARK_HOME/conf/log4j.properties \
    && mv /tmp/spark/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf

# 하둡&스파크 서비스 구동
ADD scripts/spark-services.sh $HADOOP_HOME/spark-services.sh

RUN chmod 744 -R $HADOOP_HOME
RUN $HADOOP_HOME/bin/hdfs namenode -format

# Docker autobuild test
RUN echo "hihi"

EXPOSE 50010 50020 50070 50075 50090 8020 9000
EXPOSE 10020 19888
EXPOSE 8030 8031 8032 8033 8040 8042 8088
EXPOSE 49707 2122 7001 7002 7003 7004 7005 7006 7007 8888 9000

ENTRYPOINT /usr/sbin/sshd; cd $SPARK_HOME; bash


