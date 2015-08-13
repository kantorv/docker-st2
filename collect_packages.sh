#!/bin/bash

ST2_DOWNLOAD_SERVER="https://downloads.stackstorm.net"
ST2_VER="0.12.1"
ST2_TYPE="debs"
ST2_RELEASE=5

#ST2_RELEASE=$(curl -sS -k -f "${ST2_DOWNLOAD_SERVER}/releases/st2/${ST2_VER}/${ST2_TYPE}/current/VERSION.txt")
#EXIT_CODE=$?

if [ ${EXIT_CODE} -ne 0 ]; then
    echo "Invalid or unsupported version: ${ST2_VER}"
    exit 1
else
    echo "CURRENT RELEASE FOR VERSION $ST2_VER: $ST2_RELEASE"
fi




source_dir="./packages" 
dest_dir="./docker/packages"

#URL=${DOWNLOAD_SERVER}/releases/st2/${STABLE}/${TYPE}/current/VERSION.txt
#RELEASE=$(curl -sS -k -f "$URL")



function join { local IFS="$1"; shift; echo "$*"; }

CLEAN=false

if $CLEAN; then
	read -p "You are about removing packages folders:  $source_dir and $dest_dir\nAre you sure?[y/N]"  -n 1 -r
	echo  
	if [[ $REPLY =~ ^[Yy]$ ]]; then
	    rm -rvf $source_dir 
		rm -rvf $dest_dir
	else
	    echo "Not removing foldes"
	fi

	
fi
 

if [ ! -d $source_dir ]; then
	echo " $source_dir not exists, creating"
	mkdir -p $source_dir
else
	echo " $source_dir exists"
fi


if [ ! -d $dest_dir ]; then
	echo " $dest_dir not exists, creating"
	mkdir -p $dest_dir
else
	echo " $dest_dir exists"
fi







cd $source_dir


# Constants
read -r -d '' INFO_MSG << EOM
######################################################################
######      https://github.com/StackStorm/fabric.git           #######
######################################################################
EOM



STANLEY_ZIP_URL=https://codeload.github.com/StackStorm/fabric/zip/stanley-patched
STANLEY_GIT_URL=https://github.com/StackStorm/fabric.git
STANLEY_GIT_BRANCH=stanley-patched
STANLEY_FOLDER=fabric-$STANLEY_GIT_BRANCH


[[ ! -f $STANLEY_FOLDER.zip  ]] && curl -o $STANLEY_FOLDER.zip $STANLEY_ZIP_URL 


[[ ! -d $STANLEY_FOLDER  ]] && echo "loading $STANLEY_ZIP_URL " && \
unzip  $STANLEY_FOLDER.zip  && echo "$STANLEY_FOLDER downloaded" \
|| echo "$STANLEY_FOLDER exists"



MISTRAL_STABLE_BRANCH="st2-0.9.0"

MISTRALCLIENT_URL=https://github.com/StackStorm/python-mistralclient/archive/$MISTRAL_STABLE_BRANCH.zip
MISTRALCLIENT_GIT_URL=https://github.com/StackStorm/python-mistralclient.git
MISTRALCLIENT_FOLDER=python-mistralclient-$MISTRAL_STABLE_BRANCH

[[ ! -d $MISTRALCLIENT_FOLDER  ]] && echo "cloning $MISTRALCLIENT_GIT_URL@$MISTRALCLIENT_GIT_BRANCH" && \
git clone --depth 1 -b $MISTRAL_STABLE_BRANCH  $MISTRALCLIENT_GIT_URL $MISTRALCLIENT_FOLDER &&\
   echo "$MISTRALCLIENT_GIT_URL cloned" \
|| echo "$MISTRALCLIENT_FOLDER exists"






LOGSHIPPER_URL=https://github.com/Kami/logshipper/archive/stackstorm_patched.zip
LOGSHIPPER_GIT_URL=https://github.com/Kami/logshipper.git
LOGSHIPPER_GIT_BRANCH=stackstorm_patched
LOGSHIPPERT_FOLDER=logshipper

[[ ! -d $LOGSHIPPERT_FOLDER  ]] && echo "cloning $LOGSHIPPER_GIT_BRANCH@$LOGSHIPPER_GIT_BRANCH" && \
git clone --depth 1 -b $LOGSHIPPER_GIT_BRANCH  $LOGSHIPPER_GIT_URL $LOGSHIPPERT_FOLDER &&\
   echo "$LOGSHIPPERT_FOLDER cloned" \
|| echo "$LOGSHIPPERT_FOLDER exists"





ST2_CLI_PACKAGE="st2client"
ST2_PACKAGES="st2common st2reactor st2actions st2api st2auth st2debug"
ST2_URL="$ST2_DOWNLOAD_SERVER/releases/st2/$ST2_VER/debs/current"

#echo "ST2_URL:$ST2_URL"


download_st2_pkgs() {
  #echo "###########################################################################################"
  #echo "# Downloading ubuntu packages"
  #echo "ST2_PACKAGES: ${ST2_PACKAGES}"
  #echo "ST2_CLI_PACKAGE: ${ST2_CLI_PACKAGE}"
  #echo "AXEL_: ${ST2_CLI_PACKAGE}"
  PACKAGE_LIST=()
  #exit 10
  for pkg in `echo ${ST2_PACKAGES} ${ST2_CLI_PACKAGE}`
  do
	FILENAME=${pkg}_${ST2_VER}-${ST2_RELEASE}_amd64.deb
    PACKAGE="$ST2_URL/$FILENAME"
    #echo $ST2_URL/$PACKAGE
    PACKAGE_LIST+=("$PACKAGE")
    #echo -e "\n\n\ncurl --insecure  --show-error  --remote-name  $PACKAGE"
    #curl --insecure  --show-error  --remote-name  $PACKAGE
    [[ ! -f  $FILENAME ]] && echo -e "Loading $FILENAME" &&  axel -n 3 -a $PACKAGE \
    	|| echo "$FILENAME exists" 
  done
  PACKAGE_LIST=$(join " " ${PACKAGE_LIST[@]})
  COUNT=`echo "PACKAGE_LIST:$PACKAGE_LIST" |  xargs  -n 1 echo | wc -l`
  #echo "FOUND $COUNT ST2 PACKAGES"
  #echo "PACKAGE_LIST:$PACKAGE_LIST" |  xargs  -n 1    curl -sS -k -O 

  #echo "PACKAGE_LIST:$PACKAGE_LIST" |  xargs  -n 1 -I FILE curl -sS -k -O "FILE"
}



WEBUI_URL="https://downloads.stackstorm.net/releases/st2/$ST2_VER/webui/webui-$ST2_VER.tar.gz"

download_webui() {
  [[  -f webui-$ST2_VER.tar.gz  ]]	&& echo "webui-$ST2_VER.tar.gz  exists" || axel -n 3 -a  $WEBUI_URL
}

MISTRAL_GIT_URL=https://github.com/StackStorm/mistral.git
download_mistral() {
  [[  -d ./mistral  ]]  && echo "mistral folder  exists" || git clone $MISTRAL_GIT_URL
}
ST2MISTRAL_GIT_URL=https://github.com/StackStorm/st2mistral.git
download_st2mistral() {
  [[  -d ./st2mistral  ]]  && echo "st2mistral folder  exists" ||   git clone -b ${MISTRAL_STABLE_BRANCH} https://github.com/StackStorm/st2mistral.git
}




PYCPARSER_VERSION=2.14
PYCPASTER_URL=https://pypi.python.org/packages/source/p/pycparser/pycparser-$PYCPARSER_VERSION.tar.gz 
download_pycparser() {
  [[  -d ./pycparser  ]] && echo "pycparser folder exists"  && return 
  [[ ! -f pycparser-$PYCPARSER_VERSION.tar.gz  ]]  &&  curl -O $PYCPASTER_URL
  mkdir ./pycparser && tar xzvf pycparser-$PYCPARSER_VERSION.tar.gz -C ./pycparser --strip-components=1
}




YACL_VERSION=1.0.0.0rc2
YACL_URL=https://pypi.python.org/packages/source/y/yaql/yaql-$YACL_VERSION.tar.gz
download_yaql() {
  [[  -d ./yacl  ]] && echo "yacl folder exists"  && return 
  [[ ! -f yaql-$YACL_VERSION.tar.gz  ]]  &&  curl -O $YACL_URL
  mkdir ./yacl && tar xzvf yaql-$YACL_VERSION.tar.gz  -C ./yacl --strip-components=1
}


CFFI_VERSION=1.1.2
CFFI_URL=https://pypi.python.org/packages/source/c/cffi/cffi-$CFFI_VERSION.tar.gz

download_cffi() {
  [[  -d ./cffi  ]] && echo "cffi folder exists"  && return 
  [[ ! -f cffi-$CFFI_VERSION.tar.gz  ]]  &&  curl -O $CFFI_URL
  mkdir ./cffi && tar xzvf cffi-$CFFI_VERSION.tar.gz  -C ./cffi --strip-components=1
}
 

 
download_st2_pkgs
download_webui
download_mistral
download_st2mistral
download_pycparser
download_yaql
download_cffi

#git clone --depth 1 -b st2-0.9.0  https://github.com/StackStorm/python-mistralclient.git python-mistralclient-st2-0.9.0
cd ..

cp -rf $source_dir/* $dest_dir && echo "$source_dir copied to $dest_dir"
mv  $dest_dir/*.deb $dest_dir/debs && echo "deb packages moved to $dest_dir/debs"
mv $dest_dir/debs/esl-erlang*  $dest_dir
mv $dest_dir/debs/st2client*  $dest_dir
#git clone --depth 1 -b stanley-patched  https://github.com/StackStorm/fabric.git
#
