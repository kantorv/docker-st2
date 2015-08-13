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
#RUN echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
ADD rabbitmq-signing-key-public.asc rabbitmq-signing-key-public.asc
RUN apt-key add rabbitmq-signing-key-public.asc
#RUN apt-get update -y && apt-get install -y rabbitmq-server
 
RUN apt-get install -y   make python-virtualenv python-dev realpath mongodb mongodb-server gcc git libssl-dev libyaml-dev libffi-dev libxml2-dev libxslt1-dev postgresql postgresql-contrib libpq-dev
 

#RUN git clone https://github.com/stackforge/python-mistralclient.git && \
#	cd python-mistralclient && \
#	pip install -e .

ADD requirements1.txt requirements1.txt
ADD requirements2.txt requirements2.txt
ADD requirements3.txt requirements3.txt
#ADD requirements4.txt requirements4.txt

RUN pip install -r requirements1.txt
RUN pip install -r requirements2.txt
RUN pip install -r requirements3.txt


ADD st2client.requirements.txt  st2client.requirements.txt
RUN pip install -r st2client.requirements.txt


#esl-erlang
#st2client  
#cryptography
RUN apt-get install -y libwxbase2.8-0 libwxgtk2.8-0 \
	python-dateutil python-jsonpath-rw  gdebi-core  \
	build-essential libssl-dev libffi-dev python-dev

ADD packages /packages
RUN cd /packages/pycparser && python setup.py install
RUN cd /packages/yacl && python setup.py install
RUN cd /packages/cffi && python setup.py install

 
RUN pip install cryptography psycopg2

ADD mistral.requirements.txt  mistral.requirements.txt
RUN pip install -r mistral.requirements.txt




  



RUN dpkg -i /packages/esl-erlang_18.0-1~ubuntu~trusty_amd64.deb
RUN cd /packages  && ls -al && echo "custom packages installation directory"
RUN cd /packages/fabric-stanley-patched && python setup.py install
RUN cd /packages/python-mistralclient-st2-0.9.0 && python setup.py install
RUN cd /packages/logshipper && python setup.py install



RUN cd /packages/debs &&  dpkg  -i *.deb
RUN gdebi --n /packages/st2client_0.12.1-5_amd64.deb

ADD configure_st2client_libs.sh /configure_st2client_libs.sh
RUN bash /configure_st2client_libs.sh  


RUN cd /packages/mistral && \
    python setup.py develop


RUN mkdir -p /etc/mistral/actions && \
	cd /etc/mistral/actions && \
	cp -R /packages/st2mistral . && \
	cd /etc/mistral/actions/st2mistral && \
	python setup.py develop



# rm -rf /var/lib/apt/lists/*
# Set environment variable to Docker
ENV CONTAINER DOCKER




RUN rabbitmq-plugins enable rabbitmq_management && \
	service rabbitmq-server restart && \
	rabbitmqctl status && \
	curl -sS -o /usr/bin/rabbitmqadmin http://127.0.0.1:15672/cli/rabbitmqadmin && \
	chmod 755 /usr/bin/rabbitmqadmin







#ADD  st2_deploy.main.sh /root/st2_deploy.main.sh
#RUN bash -c 'chmod +x /root/st2_deploy.main.sh'
#RUN bash -c '/root/st2_deploy.main.sh stable'



ADD configure_st2client_libs.sh /root/configure_st2client_libs.sh
RUN bash -c 'chmod +x /root/configure_st2client_libs.sh'
#RUN bash -c '/root/configure_st2client_libs.sh'




ADD tail_mongo.sh  /root/tail_mongo.sh
RUN chmod +x /root/tail_mongo.sh



############################## SSH ############################################################
RUN  if [ ! -d /root/.ssh ];then  mkdir /root/.ssh; fi
RUN if [ ! -d /var/run/sshd ]; then mkdir /var/run/sshd; fi

ADD sshkey.pub /root/.ssh/authorized_keys
RUN chown root:root /root/.ssh/authorized_keys
RUN sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config


ADD run_postgresql.sh /root/run_postgresql.sh
RUN chmod +x /root/run_postgresql.sh

ADD init_postgres.sh /root/init_postgres.sh
RUN chmod +x /root/init_postgres.sh


#supervisor configs
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# auth service
EXPOSE 9100
# api server
EXPOSE 9101
# webui
EXPOSE 8080

# ssh
EXPOSE  22

CMD env | grep _ >> /etc/environment && /usr/bin/supervisord

