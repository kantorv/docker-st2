#!/bin/bash
set -e

TYPE="debs"
SYSTEMUSER='stanley'
STANCONF="/etc/st2/st2.conf"
STAN="/home/${SYSTEMUSER}/${TYPE}"
mkdir -p ${STAN}
mkdir -p /var/log/st2

create_user() {
  if [ $(id -u ${SYSTEMUSER} &> /devnull; echo $?) != 0 ]
  then
    echo "###########################################################################################"
    echo "# Creating system user: ${SYSTEMUSER}"
    useradd ${SYSTEMUSER}
    mkdir -p /home/${SYSTEMUSER}/.ssh
    rm -Rf ${STAN}/*
    chmod 0700 /home/${SYSTEMUSER}/.ssh
    mkdir -p /home/${SYSTEMUSER}/${TYPE}
    echo "###########################################################################################"
    echo "# Generating system user ssh keys"
    ssh-keygen -f /home/${SYSTEMUSER}/.ssh/stanley_rsa -P ""
    cat /home/${SYSTEMUSER}/.ssh/stanley_rsa.pub >> /home/${SYSTEMUSER}/.ssh/authorized_keys
    chmod 0600 /home/${SYSTEMUSER}/.ssh/authorized_keys
    chown -R ${SYSTEMUSER}:${SYSTEMUSER} /home/${SYSTEMUSER}
    if [ $(grep 'stanley' /etc/sudoers.d/* &> /dev/null; echo $?) != 0 ]
    then
      echo "${SYSTEMUSER}    ALL=(ALL)       NOPASSWD: SETENV: ALL" >> /etc/sudoers.d/st2
      chmod 0440 /etc/sudoers.d/st2
    fi

    # make sure requiretty is disabled.
    sed -i "s/^Defaults\s\+requiretty/# Defaults requiretty/g" /etc/sudoers
  fi
}




WEBUI_CONFIG_PATH="/opt/stackstorm/static/webui/config.js"
CLI_CONFIG_DIRECTORY_PATH=${HOME}/.st2
CLI_CONFIG_RC_FILE_PATH=${CLI_CONFIG_DIRECTORY_PATH}/config


# Information about a test account which used by st2_deploy
TEST_ACCOUNT_USERNAME="testu"
TEST_ACCOUNT_PASSWORD="testp"

# Content for the test htpasswd file used by auth
AUTH_FILE_PATH="/etc/st2/htpasswd"
HTPASSWD_FILE_CONTENT="testu:{SHA}V1t6eZLxnehb7CTBuj61Nq3lIh4="



install_st2client() {
	
  # Delete existing config directory (if exists)
  if [ -e "${CLI_CONFIG_DIRECTORY_PATH}" ]; then
    rm -r ${CLI_CONFIG_DIRECTORY_PATH}
  fi

  # Write the CLI config file with the default credentials
  mkdir -p ${CLI_CONFIG_DIRECTORY_PATH}

  bash -c "cat > ${CLI_CONFIG_RC_FILE_PATH}" <<EOL
[general]
base_url = http://127.0.0.1

[credentials]
username = ${TEST_ACCOUNT_USERNAME}
password = ${TEST_ACCOUNT_PASSWORD}
EOL
}

install_webui() {
  echo "###########################################################################################"
  echo "# Installing st2web"
  # Copy the files over to the webui static root
  mkdir -p /opt/stackstorm/static/webui && \
  	cd /opt/stackstorm/static/webui && \
  	tar -xzvf /packages/webui-0.12.1.tar.gz  --strip-components=1 && \
  	cd /


  # Replace config.js
  echo -e "'use strict';
  angular.module('main')
    .constant('st2Config', {
    hosts: [{
      name: 'StackStorm',
      url: '//:9101',
      auth: '//:9100'
    }]
  });" > ${WEBUI_CONFIG_PATH}

  sed -i "s%^# allow_origin =.*\$%allow_origin = *%g" ${STANCONF}

  # Cleanup
 
}




function setup_auth() {
    echo "###########################################################################################"
    echo "# Setting up authentication service"

    # Install test htpasswd file
    if [[ ! -f ${AUTH_FILE_PATH} ]]; then
        # File doesn't exist yet
        echo "${HTPASSWD_FILE_CONTENT}" >> ${AUTH_FILE_PATH}
    elif [ -f ${AUTH_FILE_PATH} ] && [ ! `grep -Fxq "${HTPASSWD_FILE_CONTENT}" ${AUTH_FILE_PATH}` ]; then
        # File exists, but the line is not present yet
        echo "${HTPASSWD_FILE_CONTENT}" >> ${AUTH_FILE_PATH}
    fi

    # Configure st2auth to run in standalone mode with the created htpasswd file
    sed -i "s#^mode = proxy\$#mode = standalone#g" ${STANCONF}
    sed -i "s#^backend_kwargs =\$#backend_kwargs = {\"file_path\": \"${AUTH_FILE_PATH}\"}#g" ${STANCONF}
}



PYTHONPACK="/usr/lib/python2.7/dist-packages"
PYTHON=`which python`


migrate_rules() {
  echo "###########################################################################################"
  echo "# Migrating rules (pack inclusion)."
  $PYTHON ${PYTHONPACK}/st2common/bin/migrate_rules_to_include_pack.py
}

register_content() {
  echo "###########################################################################################"
  echo "# Registering all content"
  $PYTHON ${PYTHONPACK}/st2common/bin/st2-register-content --register-sensors --register-actions --config-file ${STANCONF}
}





create_user
setup_auth
install_st2client
install_webui
#migrate_rules
#register_content