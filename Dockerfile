FROM ubuntu:latest

RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get -y install wget ssh openjdk-11-jdk-headless

# Download and unpack Hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz --progress=bar:force:noscroll \
    && tar xf hadoop-3.3.4.tar.gz \
    && mv hadoop-3.3.4 /usr/local/hadoop \
    && rm hadoop-3.3.4.tar.gz

RUN wget https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz --progress=bar:force:noscroll \
    && tar xf spark-3.3.2-bin-hadoop3.tgz \
    && mv spark-3.3.2-bin-hadoop3 /opt/spark \
    && rm spark-3.3.2-bin-hadoop3.tgz

# Only used for manual testing
RUN apt-get -y install vim

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV SPARK_HOME=/opt/spark
ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop

RUN apt-get update && \
    apt install -y python3 python3-pip && \
    pip3 install --upgrade pip setuptools && \
    # Removed the .cache to save space
    rm -r /root/.cache && rm -rf /var/cache/apt/*


# Generate keys to allow for node communication via SSH. Pseudo-distribute mode simulates this behavior locally.
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
RUN cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Setup necessary 'HADOOP_HOME' variable and add Hadoop binaries to 'PATH'
ENV HADOOP_HOME=/usr/local/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin

# Not sure why this is necessary, something about Hadoop 3.x.x introducing this
ENV HDFS_NAMENODE_USER="root"
ENV HDFS_DATANODE_USER="root"
ENV HDFS_SECONDARYNAMENODE_USER="root"
ENV YARN_RESOURCEMANAGER_USER="root"
ENV YARN_NODEMANAGER_USER="root"

COPY startup.sh $HADOOP_HOME/startup.sh
COPY hadoop_config /usr/local/hadoop/etc/hadoop
COPY ssh_config/config /root/.ssh/

RUN chmod 744 -R $HADOOP_HOME

EXPOSE 9870 9864 9868 8088 9000 8042 4040

ENTRYPOINT $HADOOP_HOME/startup.sh; bash
