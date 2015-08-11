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
ADD sources.il.list /etc/apt/sources.list
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
RUN apt-get update -y && apt-get install -y rabbitmq-server
 
RUN apt-get install -y   make python-virtualenv python-dev realpath mongodb mongodb-server gcc git libssl-dev libyaml-dev libffi-dev libxml2-dev libxslt1-dev postgresql postgresql-contrib libpq-dev
 

#RUN git clone https://github.com/stackforge/python-mistralclient.git && \
#	cd python-mistralclient && \
#	pip install -e .

ADD requirements.txt  requirements.txt
ADD requirements.txt  st2client.requirements.txt
RUN pip install -r requirements.txt
RUN pip install -r st2client.requirements.txt

ADD packages /packages 


RUN cd /packages  && ls -al && echo "custom packages installation directory"
RUN cd /packages/fabric-stanley-patched && python setup.py install
RUN cd /packages/python-mistralclient-st2-0.9.0 && python setup.py install

RUN apt-get install -y  python-dateutil python-jsonpath-rw
RUN cd /packages &&  dpkg  -i *.deb
RUN apt-get -y install gdebi-core &&  \
    gdebi --n /packages/st2client_0.12.1-5_amd64.deb
	


# rm -rf /var/lib/apt/lists/*
# Set environment variable to Docker
ENV CONTAINER DOCKER




RUN rabbitmq-plugins enable rabbitmq_management && \
	service rabbitmq-server restart && \
	rabbitmqctl status && \
	curl -sS -o /usr/bin/rabbitmqadmin http://127.0.0.1:15672/cli/rabbitmqadmin && \
	chmod 755 /usr/bin/rabbitmqadmin



ADD  st2_deploy.main.sh /root/st2_deploy.main.sh

RUN bash -c 'chmod +x /root/st2_deploy.main.sh'
#RUN bash -c '/root/st2_deploy.main.sh stable'

ADD . /root/st2/

#RUN bash -c 'chmod +x /root/st2/start.sh'

# auth service
EXPOSE 9100
# api server
EXPOSE 9101
# webui
EXPOSE 8080
