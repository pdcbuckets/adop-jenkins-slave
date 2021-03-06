FROM centos:centos7.2.1511
MAINTAINER "Nick Griffin" <nicholas.griffin@accenture.com>

# Java Env Variables
ENV JAVA_RPM=jdk-8u144-linux-x64.rpm \
    JAVA_RPM_URL=http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/${JAVA_RPM} \
    JAVA_HOME=/usr/java/jdk1.8.0_144

# Swarm Env Variables (defaults)
ENV SWARM_MASTER=http://jenkins:8080/jenkins/
ENV SWARM_USER=jenkins
ENV SWARM_PASSWORD=jenkins

# Slave Env Variables
ENV SLAVE_NAME="Swarm_Slave"
ENV SLAVE_LABELS="docker aws ldap"
ENV SLAVE_MODE="exclusive"
ENV SLAVE_EXECUTORS=1
ENV SLAVE_DESCRIPTION="Core Jenkins Slave"

# Pre-requisites
RUN yum -y install epel-release
RUN yum install -y which \
    git \
    wget \
    tar \
    zip \
    unzip \
    openldap-clients \
    openssl \
    python-pip \
    libxslt && \
    yum clean all 

RUN pip install awscli==1.10.19

# Docker versions Env Variables
ENV DOCKER_ENGINE_VERSION=1.10.3-1.el7.centos
ENV DOCKER_COMPOSE_VERSION=1.6.0
ENV DOCKER_MACHINE_VERSION=v0.6.0

RUN curl -fsSL https://get.docker.com/ | sed "s/docker-engine/docker-engine-${DOCKER_ENGINE_VERSION}/" | sh

RUN curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose
RUN curl -L https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}/docker-machine-`uname -s`-`uname -m` >/usr/local/bin/docker-machine && \
    chmod +x /usr/local/bin/docker-machine

# Install Java
RUN wget --no-cookies --no-check-certificate -O ${JAVA_RPM} \
    --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "${JAVA_RPM_URL}/${JAVA_RPM}" && \
    rpm -ivh ${JAVA_RPM} && \
    rm -f ${JAVA_RPM}

# Make Jenkins a slave by installing swarm-client
RUN curl -s -o /bin/swarm-client.jar -k http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/2.0/swarm-client-2.0-jar-with-dependencies.jar

# Install JQ CLI
RUN curl -fsSL -o /usr/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" && \
    chmod +x /usr/bin/jq

# Install Ansible
RUN yum -y install ansible && \
    yum -y install python-boto && \
    sed -i 's/#host_key_checking/host_key_checking/g' /etc/ansible/ansible.cfg && \
    ansible --version

# Install OpenShift CLI Tool
RUN curl -fsSL https://github.com/openshift/origin/releases/download/v1.5.1/openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit.tar.gz | tar xzf - -C /usr/bin/ --strip-components 1 openshift-origin-client-tools-v1.5.1-7b451fc-linux-64bit/oc

# Start Swarm-Client
CMD java -jar /bin/swarm-client.jar -executors ${SLAVE_EXECUTORS} -description "${SLAVE_DESCRIPTION}" -master ${SWARM_MASTER} -username ${SWARM_USER} -password ${SWARM_PASSWORD} -name "${SLAVE_NAME}" -labels "${SLAVE_LABELS}" -mode ${SLAVE_MODE}
