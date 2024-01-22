FROM ubuntu:latest

RUN apt-get update
RUN apt-get -y dist-upgrade
RUN apt-get -y install wget curl ssh openjdk-11-jdk-headless

# Download and unpack Hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz --progress=bar:force:noscroll \
    && tar xf hadoop-3.3.5.tar.gz \
    && mv hadoop-3.3.5 /usr/local/hadoop \
    && rm hadoop-3.3.5.tar.gz

RUN wget https://dlcdn.apache.org/spark/spark-3.3.4/spark-3.3.4-bin-hadoop3.tgz --progress=bar:force:noscroll \
    && tar xf spark-3.3.4-bin-hadoop3.tgz \
    && mv spark-3.3.4-bin-hadoop3 /opt/spark \
    && rm spark-3.3.4-bin-hadoop3.tgz

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

RUN chmod 755 -R $HADOOP_HOME
RUN mkdir /code

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-liberation \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in aarch64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
WORKDIR /tmp
RUN pip install notebook && \
    jupyter notebook --generate-config 
RUN echo "c.NotebookApp.notebook_dir ='/code'" > /root/.jupyter/jupyter_notebook_config.py
ENV JUPYTER_PORT=8888

RUN pip install snakebite-py3 protobuf==3.20.*

EXPOSE 9870 9864 9868 8088 9000 8042 4040 8888

ENTRYPOINT $HADOOP_HOME/startup.sh; bash
