#!/usr/bin/env bash
echo "ENTERED ST2DEPLOY"


BASE_URL="https://downloads.stackstorm.net/releases/st2"
BOOTSTRAP_FILE="/tmp/st2_boostrap.sh"

#STABLE=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_stable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`
#LATEST=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_unstable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`

STABLE="0.12.1" 
LATEST="0.13dev"


if [ -z $1 ]; then
    ST2VER=${STABLE}
else
    if [[ "$1" == "stable" ]]; then
        ST2VER=${STABLE}
    elif [[ "$1" == "latest" ]]; then
        ST2VER=${LATEST}
    else
        ST2VER=$1
    fi

fi



echo "STABLE:$STABLE LATEST:$LATEST ST2VER:$ST2VER"



DEBTEST=`lsb_release -a 2> /dev/null | grep Distributor | awk '{print $3}'`
echo "VERSION:$ST2VER"
TYPE="debs"

ST2DEPLOY="${BASE_URL}/${ST2VER}/${TYPE}/st2_deploy.sh"

 
#CURLTEST=`curl --output /dev/null --silent --head --fail ${ST2DEPLOY}`


 


echo "DEBTEST:$DEBTEST ST2DEPLOY:$ST2DEPLOY BOOTSTRAP_FILE:$BOOTSTRAP_FILE"



# Constants
read -r -d '' WARNING_MSG << EOM
######################################################################
######                       WARNING                           #######
######################################################################

This scripts allows you to evaluate StackStorm on a single server and
is not intended to be used for production deployments.

For more information, see http://docs.stackstorm.com/install/index.html
EOM

WARNING_SLEEP_DELAY=1

# Options which can be provied by the user via env variables
INSTALL_ST2CLIENT=${INSTALL_ST2CLIENT:-1}
INSTALL_WEBUI=${INSTALL_WEBUI:-1}
INSTALL_MISTRAL=${INSTALL_MISTRAL:-1}
INSTALL_CLOUDSLANG=${INSTALL_CLOUDSLANG:-0}
INSTALL_WINDOWS_RUNNER_DEPENDENCIES=${INSTALL_WINDOWS_RUNNER_DEPENDENCIES:-1}

echo "INSTALL_ST2CLIENT:$INSTALL_ST2CLIENT"
echo "INSTALL_WEBUI:$INSTALL_WEBUI"
echo "INSTALL_MISTRAL:$INSTALL_MISTRAL"
echo "INSTALL_CLOUDSLANG:$INSTALL_CLOUDSLANG"
echo "INSTALL_WINDOWS_RUNNER_DEPENDENCIES:$INSTALL_WINDOWS_RUNNER_DEPENDENCIES"


# Common variables
DOWNLOAD_SERVER='https://downloads.stackstorm.net'
RABBIT_PUBLIC_KEY="rabbitmq-signing-key-public.asc"
PACKAGES="st2common st2reactor st2actions st2api st2auth st2debug"
CLI_PACKAGE="st2client"
PYTHON=`which python`
BUILD="current"
DEBTEST=`lsb_release -a 2> /dev/null | grep Distributor | awk '{print $3}'`
SYSTEMUSER='stanley'
STANCONF="/etc/st2/st2.conf"

CLI_CONFIG_DIRECTORY_PATH=${HOME}/.st2
CLI_CONFIG_RC_FILE_PATH=${CLI_CONFIG_DIRECTORY_PATH}/confi


echo "CLI_CONFIG_DIRECTORY_PATH:$CLI_CONFIG_DIRECTORY_PATH"
echo "CLI_CONFIG_RC_FILE_PATH:$CLI_CONFIG_RC_FILE_PATH"


# Information about a test account which used by st2_deploy
TEST_ACCOUNT_USERNAME="testu"
TEST_ACCOUNT_PASSWORD="testp"

# Content for the test htpasswd file used by auth
AUTH_FILE_PATH="/etc/st2/htpasswd"
HTPASSWD_FILE_CONTENT="testu:{SHA}V1t6eZLxnehb7CTBuj61Nq3lIh4="

# WebUI
WEBUI_CONFIG_PATH="/opt/stackstorm/static/webui/config.js"

# CloudSlang variables
CLOUDLSNAG_CLI_VERSION=${CLOUDLSNAG_CLI_VERSION:-cloudslang-0.7.35}
CLOUDLSNAG_CLI_ZIP_NAME=${CLOUDLSNAG_CLI_ZIP_NAME:-cslang-cli-with-content.zip}
CLOUDSLANG_REPO=${CLOUDSLANG_REPO:-CloudSlang/cloud-slang}
CLOUDSLANG_ZIP_URL=https://github.com/${CLOUDSLANG_REPO}/releases/download/${CLOUDLSNAG_CLI_VERSION}/${CLOUDLSNAG_CLI_ZIP_NAME}
CLOUDSLANG_EXEC_PATH=${CLOUDSLANG_EXEC_PATH:-cslang/bin/cslang}




# Common utility functions
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -V | tail -n 1)" == "$1"; }
function join { local IFS="$1"; shift; echo "$*"; }

# Distribution specific variables
APT_PACKAGE_LIST=("" "rabbitmq-server" "make" "python-virtualenv" "python-dev" "realpath" "mongodb" "mongodb-server" "gcc" "git")


#python-pip rabbitmq-server  python-virtualenv python-dev gcc git make
echo "APT_PACKAGE_LIST: $APT_PACKAGE_LIST"



# Add windows runner dependencies
# Note: winexe is provided by Stackstorm repos
if [ ${INSTALL_WINDOWS_RUNNER_DEPENDENCIES} == "1" ]; then
  APT_PACKAGE_LIST+=("smbclient" "winexe")
  YUM_PACKAGE_LIST+=("samba-client" "winexe")
fi



if [ ${INSTALL_CLOUDSLANG} == "1" ]; then
  APT_PACKAGE_LIST+=("unzip" "openjdk-7-jre")
  YUM_PACKAGE_LIST+=("unzip" "java-1.7.0-openjdk")
fi

APT_PACKAGE_LIST=$(join " " ${APT_PACKAGE_LIST[@]})
YUM_PACKAGE_LIST=$(join " " ${YUM_PACKAGE_LIST[@]})


echo "APT_PACKAGE_LIST : $APT_PACKAGE_LIST"
 
#STABLE=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_stable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`
#LATEST=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_unstable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`


echo "STABLE : $STABLE, LATEST:$LATEST"
#exit 4

# Actual code starts here

echo "${WARNING_MSG}"
echo ""
echo "To abort press CTRL-C otherwise installation will continue in ${WARNING_SLEEP_DELAY} seconds"
sleep ${WARNING_SLEEP_DELAY}

if [ -z $1 ]
then
  VER=${STABLE}
elif [[ "$1" == "latest" ]]; then
   VER=${LATEST}
else
  VER=$1
fi

echo "Installing version ${VER}"

# Determine which mistral version to use
if version_ge $VER "0.9"; then
    MISTRAL_STABLE_BRANCH="st2-0.9.0"
elif version_ge $VER "0.8.1"; then
    MISTRAL_STABLE_BRANCH="st2-0.8.1"
elif version_ge $VER "0.8"; then
    MISTRAL_STABLE_BRANCH="st2-0.8.0"
else
    MISTRAL_STABLE_BRANCH="st2-0.5.1"
fi



echo "MISTRAL_STABLE_BRANCH:$MISTRAL_STABLE_BRANCH"

if [[ "$DEBTEST" == "Ubuntu" ]]; then
  TYPE="debs"
  PYTHONPACK="/usr/lib/python2.7/dist-packages"
  echo "###########################################################################################"
  echo "# Detected Distro is ${DEBTEST}"
else
  echo "Unknown Operating System"
  exit 2
fi

URL=${DOWNLOAD_SERVER}/releases/st2/${STABLE}/${TYPE}/current/VERSION.txt
echo "URL:$URL"

RELEASE=5
#RELEASE=$(curl -sS -k -f "$URL")
#EXIT_CODE=$?
EXIT_CODE=0
echo $RELEASE

if [ ${EXIT_CODE} -ne 0 ]; then
    echo "Invalid or unsupported version: ${VER}"
    exit 1
fi

# From here on, fail on errors
set -e

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


setup_mistral_st2_config()
{
  echo "" >> ${STANCONF}
  echo "[mistral]" >> ${STANCONF}
  echo "v2_base_url = http://127.0.0.1:8989/v2" >> ${STANCONF}
}

setup_postgresql() {
  # Setup the postgresql service on fedora. Ubuntu is already setup by default.
  if [[ "$TYPE" == "rpms" ]]; then
    echo "Configuring PostgreSQL for Fedora..."
    systemctl enable postgresql
    sudo postgresql-setup initdb
    pg_hba_config=/var/lib/pgsql/data/pg_hba.conf
    sed -i 's/^local\s\+all\s\+all\s\+peer/local all all trust/g' ${pg_hba_config}
    sed -i 's/^local\s\+all\s\+all\s\+ident/local all all trust/g' ${pg_hba_config}
    sed -i 's/^host\s\+all\s\+all\s\+127.0.0.1\/32\s\+ident/host all all 127.0.0.1\/32 md5/g' ${pg_hba_config}
    sed -i 's/^host\s\+all\s\+all\s\+::1\/128\s\+ident/host all all ::1\/128 md5/g' ${pg_hba_config}
    systemctl start postgresql
  fi

  echo "Changing max connections for PostgreSQL..."
  config=`sudo -u postgres psql -c "SHOW config_file;" | grep postgresql.conf`
  sed -i 's/max_connections = 100/max_connections = 500/' ${config}
  service postgresql restart
}

setup_mistral_config()
{
config=/etc/mistral/mistral.conf
echo "Writing Mistral configuration file to $config..."
if [ -e "$config" ]; then
  rm $config
fi
touch $config
cat <<mistral_config >$config
[database]
connection=postgresql://mistral:StackStorm@localhost/mistral
max_pool_size=50

[pecan]
auth_enable=false
mistral_config
}

setup_mistral_log_config()
{
log_config=/etc/mistral/wf_trace_logging.conf
echo "Writing Mistral log configuration file to $log_config..."
if [ -e "$log_config" ]; then
    rm $log_config
fi
cp /opt/openstack/mistral/etc/wf_trace_logging.conf.sample $log_config
sed -i "s~tmp~var/log~g" $log_config
}

setup_mistral_db()
{
  echo "Setting up Mistral DB in PostgreSQL..."
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS mistral;"
  sudo -u postgres psql -c "DROP USER IF EXISTS mistral;"
  sudo -u postgres psql -c "CREATE USER mistral WITH ENCRYPTED PASSWORD 'StackStorm';"
  sudo -u postgres psql -c "CREATE DATABASE mistral OWNER mistral;"

  echo "Creating and populating DB tables for Mistral..."
  config=/etc/mistral/mistral.conf
  cd /opt/openstack/mistral
  /opt/openstack/mistral/.venv/bin/python ./tools/sync_db.py --config-file ${config}
}

setup_mistral_upstart()
{
echo "Setting up upstart for Mistral..."
upstart=/etc/init/mistral.conf
if [ -e "$upstart" ]; then
    rm $upstart
fi
touch $upstart
cat <<mistral_upstart >$upstart
description "Mistral Workflow Service"

start on runlevel [2345]
stop on runlevel [016]
respawn

exec /opt/openstack/mistral/.venv/bin/python /opt/openstack/mistral/mistral/cmd/launch.py --config-file /etc/mistral/mistral.conf --log-config-append /etc/mistral/wf_trace_logging.conf
mistral_upstart
}

setup_mistral_systemd()
{
echo "Setting up systemd for Mistral..."
systemd=/etc/systemd/system/mistral.service
if [ -e "$systemd" ]; then
    rm $systemd
fi
touch $systemd
cat <<mistral_systemd >$systemd
[Unit]
Description=Mistral Workflow Service

[Service]
ExecStart=/opt/openstack/mistral/.venv/bin/python /opt/openstack/mistral/mistral/cmd/launch.py --config-file /etc/mistral/mistral.conf --log-file /var/log/mistral.log --log-config-append /etc/mistral/wf_trace_logging.conf
Restart=on-abort

[Install]
WantedBy=multi-user.target
mistral_systemd
systemctl enable mistral
}

setup_mistral() {
  echo "###########################################################################################"
  echo "# Setting up Mistral"

  # Clone mistral from github.
  mkdir -p /opt/openstack
  cd /opt/openstack
  if [ -d "/opt/openstack/mistral" ]; then
    rm -r /opt/openstack/mistral
  fi
  echo "Cloning Mistral branch: ${MISTRAL_STABLE_BRANCH}..."
  git clone -b ${MISTRAL_STABLE_BRANCH} https://github.com/StackStorm/mistral.git

  # Setup virtualenv for running mistral.
  cd /opt/openstack/mistral
  virtualenv --no-site-packages .venv
  . /opt/openstack/mistral/.venv/bin/activate
  pip install -q -r requirements.txt
  pip install -q psycopg2
  python setup.py develop

  # Setup plugins for actions.
  mkdir -p /etc/mistral/actions
  if [ -d "/etc/mistral/actions/st2mistral" ]; then
    rm -r /etc/mistral/actions/st2mistral
  fi
  echo "Cloning St2mistral branch: ${MISTRAL_STABLE_BRANCH}..."
  cd /etc/mistral/actions
  git clone -b ${MISTRAL_STABLE_BRANCH} https://github.com/StackStorm/st2mistral.git
  cd /etc/mistral/actions/st2mistral
  python setup.py develop

  # Create configuration files.
  mkdir -p /etc/mistral
  setup_mistral_config
  setup_mistral_log_config
  setup_mistral_st2_config

  # Setup database.
  setup_postgresql
  setup_mistral_db

  # Setup service.
  if [[ "$TYPE" == "debs" ]]; then
    setup_mistral_upstart
  elif [[ "$TYPE" == "rpms" ]]; then
    setup_mistral_systemd
  fi

  # Deactivate venv.
  deactivate

  # Setup mistral client.
  pip install -q -U git+https://github.com/StackStorm/python-mistralclient.git@${MISTRAL_STABLE_BRANCH}
}

setup_cloudslang() {
  echo "###########################################################################################"
  echo "# Setting up CloudSlang"

  cd /opt
  if [ -d "/opt/cslang" ]; then
    rm -rf /opt/cslang
  fi

  echo "Downloading CloudSlang CLI"
  curl -Ss -Lk -o cslang-cli.zip ${CLOUDSLANG_ZIP_URL}

  echo "Unzipping CloudSlang CLI"
  unzip cslang-cli.zip

  echo "Chmoding CloudSlang executables"
  chmod +x ${CLOUDSLANG_EXEC_PATH}

  echo "Deleting cslang-cli zip file"
  rm cslang-cli.zip
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

download_pkgs() {
  echo "###########################################################################################"
  echo "# Downloading ${TYPE} packages"
  echo "ST2 Packages: ${PACKAGES}"
  echo "CLI_PACKAGE: ${CLI_PACKAGE}"
  #exit 10
  pushd ${STAN}
  for pkg in `echo ${PACKAGES} ${CLI_PACKAGE}`
  do
    if [[ "$TYPE" == "debs" ]]; then
      PACKAGE="${pkg}_${VER}-${RELEASE}_amd64.deb"
    elif [[ "$TYPE" == "rpms" ]]; then
      PACKAGE="${pkg}-${VER}-${RELEASE}.noarch.rpm"
    fi

    # Clean up a bit if older versions exist
    old_package=$(ls *${pkg}* 2> /dev/null | wc -l)
    if [ "${old_package}" != "0" ]; then
      rm -f *${pkg}*
    fi
    echo "Download candidate for $PACKAGE:${DOWNLOAD_SERVER}/releases/st2/${VER}/${TYPE}/${BUILD}/${PACKAGE}"
    #curl -sS -k -O ${DOWNLOAD_SERVER}/releases/st2/${VER}/${TYPE}/${BUILD}/${PACKAGE}
  done
  popd
}



deploy_deb() {
  pushd ${STAN}
  for PACKAGE in $PACKAGES; do
    echo "###########################################################################################"
    echo "# Removing ${PACKAGE}"
    dpkg --purge $PACKAGE
    echo "###########################################################################################"
    echo "# Installing ${PACKAGE} ${VER}"
    dpkg -i ${PACKAGE}*
  done
  popd
}

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
download_pkgs


exit 5

if [[ "$TYPE" == "debs" ]]; then
  install_apt
  deploy_deb
elif [[ "$TYPE" == "rpms" ]]; then
  install_yum
  deploy_rpm
fi

if [ ${INSTALL_MISTRAL} == "1" ]; then
  setup_mistral
fi

if [ ${INSTALL_CLOUDSLANG} == "1" ]; then
  setup_cloudslang
fi

install_st2client() {
  pushd ${STAN}
  echo "###########################################################################################"
  echo "# Installing st2client requirements via pip"
  curl -sS -k -o /tmp/st2client-requirements.txt https://raw.githubusercontent.com/StackStorm/st2/master/st2client/requirements.txt
  pip install -q -U -r /tmp/st2client-requirements.txt
  if [[ "$TYPE" == "debs" ]]; then
    echo "########## Removing st2client ##########"
    if dpkg -l | grep st2client; then
        apt-get -y purge python-st2client
    fi
    echo "########## Installing st2client ${VER} ##########"
    apt-get -y install gdebi-core
    gdebi --n st2client*
  elif [[ "$TYPE" == "rpms" ]]; then
    yum localinstall -y st2client-${VER}-${RELEASE}.noarch.rpm
  fi
  popd

  # Write ST2_BASE_URL to env
  if [[ "$TYPE" == "rpms" ]]; then
    BASHRC=/etc/bashrc
    echo "" >> ${BASHRC}
    echo "export ST2_BASE_URL='http://127.0.0.1'" >> ${BASHRC}
  fi

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
  # Download artifact
  curl -sS -k -f -o /tmp/webui.tar.gz "${DOWNLOAD_SERVER}/releases/st2/${VER}/webui/webui-${VER}.tar.gz"

  # Unpack it into a temporary directory
  temp_dir=$(mktemp -d)
  tar -xzvf /tmp/webui.tar.gz -C ${temp_dir} --strip-components=1

  # Copy the files over to the webui static root
  mkdir -p /opt/stackstorm/static/webui
  cp -R ${temp_dir}/* /opt/stackstorm/static/webui

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
  rm -r ${temp_dir}
  rm -f /tmp/webui.tar.gz
}

setup_auth

if [ ${INSTALL_ST2CLIENT} == "1" ]; then
    install_st2client
fi

if [ ${INSTALL_WEBUI} == "1" ]; then
    install_webui
fi

if version_ge $VER "0.9"; then
  migrate_rules
fi
register_content
echo "###########################################################################################"
echo "# Starting St2 Services"
st2ctl restart
sleep 20
##This is a hack around a weird issue with actions getting stuck in scheduled state
TOKEN=`st2 auth ${TEST_ACCOUNT_USERNAME} -p ${TEST_ACCOUNT_PASSWORD} | grep token | awk '{print $4}'`
ST2_AUTH_TOKEN=${TOKEN} st2 run core.local date &> /dev/null
ACTIONEXIT=$?
## Clean up token
rm -Rf /home/${SYSTEMUSER}/.st2
echo "=========================================="
echo ""

if [ ! "${ACTIONEXIT}" == 0 ]
then
  echo "ERROR!"
  echo "Something went wrong, st2 failed to start"
  exit 2
else
  echo "          _   ___     ____  _  __ "
  echo "         | | |__ \   / __ \| |/ / "
  echo "      ___| |_   ) | | |  | | ' /  "
  echo "     / __| __| / /  | |  | |  <   "
  echo "     \__ \ |_ / /_  | |__| | . \  "
  echo "     |___/\__|____|  \____/|_|\_\ "
  echo ""
  echo "  st2 is installed and ready to use."
fi

echo "=========================================="
echo ""

echo "Test StackStorm user account details"
echo ""
echo "Username: ${TEST_ACCOUNT_USERNAME}"
echo "Password: ${TEST_ACCOUNT_PASSWORD}"
echo ""
echo "Test account credentials were also written to the default CLI config at ${CLI_CONFIG_PATH}."
echo ""
echo "To login and obtain an authentication token, run the following command:"
echo ""
echo "st2 auth ${TEST_ACCOUNT_USERNAME} -p ${TEST_ACCOUNT_PASSWORD}"
echo ""
echo "For more information see http://docs.stackstorm.com/authentication.html#usage"
exit 0

