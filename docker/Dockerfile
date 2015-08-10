# Pull base image.
FROM ubuntu:14.04.2

# Disable prompts
ENV DEBIAN_FRONTEND noninteractive

# Reset policy-rc.d
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d


# Set locale (fix the locale warnings)
RUN locale-gen --purge en_US.UTF-8
RUN echo  'LANG="en_US.UTF-8"' > /etc/default/locale
RUN echo   'LANGUAGE="en_US:en"' >> /etc/default/locale

# Set timezone
RUN echo "Asia/Jerusalem"  > /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

#remo
RUN rm /etc/apt/sources.list
ADD sources.local.list /etc/apt/sources.list
#RUN   echo "192.115.211.70       ubuntu.mirror" >> /etc/hosts
#192.115.211.70 ubuntu.mirror
#echo "10.0.0.22       ubuntu.mirror"




# Install Python
RUN apt-get update -y

RUN apt-get install -y \
		curl python python-dev python-pip python-virtualenv supervisor build-essential openssh-server \
		python-prettytable python-yaml 



#RABBITMQ
RUN echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
ADD rabbitmq-signing-key-public.asc rabbitmq-signing-key-public.asc
RUN apt-key add rabbitmq-signing-key-public.asc
RUN apt-get install -y rabbitmq-server

# rm -rf /var/lib/apt/lists/*
# Set environment variable to Docker
ENV CONTAINER DOCKER

RUN cd /root && curl -sS -k -O https://ops.stackstorm.net/releases/st2/scripts/st2_deploy.sh

RUN bash -c 'chmod +x /root/st2_deploy.sh'

RUN bash -c '/root/st2_deploy.sh stable || exit 2'

ADD . /root/st2/

RUN bash -c 'chmod +x /root/st2/start.sh'

# auth service
EXPOSE 9100
# api server
EXPOSE 9101
# webui
EXPOSE 8080
