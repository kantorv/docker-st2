#!/usr/bin/env bash
echo "ENTERED ST2DEPLOY"


BASE_URL="https://downloads.stackstorm.net/releases/st2"
BOOTSTRAP_FILE="/tmp/st2_boostrap.sh"

#STABLE=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_stable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`
#LATEST=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_unstable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`

STABLE="0.12.1" 
LATEST="0.13dev"



# Common utility functions
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -V | tail -n 1)" == "$1"; }
function join { local IFS="$1"; shift; echo "$*"; }

 

  


 
#STABLE=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_stable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`
#LATEST=`curl -Ss -q https://downloads.stackstorm.net/deb/pool/trusty_unstable/main/s/st2api/ | grep 'amd64.deb' | sed -e "s~.*>st2api_\(.*\)-.*<.*~\1~g" | sort --version-sort -r | uniq | head -n 1`






RELEASE=5





 

exit 0

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

