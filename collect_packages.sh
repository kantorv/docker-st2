#!/bin/bash

source_dir="./packages" 
dest_dir="./docker/packages"


function join { local IFS="$1"; shift; echo "$*"; }

CLEAN=true

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




MISTRALCLIENT_URL=https://github.com/StackStorm/python-mistralclient/archive/st2-0.9.0.zip
MISTRALCLIENT_GIT_URL=https://github.com/StackStorm/python-mistralclient.git
MISTRALCLIENT_GIT_BRANCH=st2-0.9.0
MISTRALCLIENT_FOLDER=python-mistralclient-$MISTRALCLIENT_GIT_BRANCH

[[ ! -d $MISTRALCLIENT_FOLDER  ]] && echo "cloning $MISTRALCLIENT_GIT_URL@$MISTRALCLIENT_GIT_BRANCH" && \
git clone --depth 1 -b $MISTRALCLIENT_GIT_BRANCH  $MISTRALCLIENT_GIT_URL $MISTRALCLIENT_FOLDER &&\
   echo "$MISTRALCLIENT_GIT_URL cloned" \
|| echo "$MISTRALCLIENT_FOLDER exists"



ST2_CLI_PACKAGE="st2client"
ST2_PACKAGES="st2common st2reactor st2actions st2api st2auth st2debug"
ST2_DOWNLOAD_SERVER="https://downloads.stackstorm.net"
ST2_VER="0.12.1"
ST2_BUILD="current"

ST2_URL="$ST2_DOWNLOAD_SERVER/releases/st2/$ST2_VER/debs/current"
ST2_RELEASE=5
echo "ST2_URL:$ST2_URL"




download_pkgs() {
  echo "###########################################################################################"
  echo "# Downloading ubuntu packages"
  echo "ST2_PACKAGES: ${ST2_PACKAGES}"
  echo "ST2_CLI_PACKAGE: ${ST2_CLI_PACKAGE}"
  echo "AXEL_: ${ST2_CLI_PACKAGE}"
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
  echo "FOUND $COUNT ST2 PACKAGES"
  #echo "PACKAGE_LIST:$PACKAGE_LIST" |  xargs  -n 1    curl -sS -k -O 

  #echo "PACKAGE_LIST:$PACKAGE_LIST" |  xargs  -n 1 -I FILE curl -sS -k -O "FILE"
}

download_pkgs

#download_pkgs



#git clone --depth 1 -b st2-0.9.0  https://github.com/StackStorm/python-mistralclient.git python-mistralclient-st2-0.9.0
cd ..

cp -rf $source_dir/* $dest_dir && echo "$source_dir copied to $dest_dir"
#git clone --depth 1 -b stanley-patched  https://github.com/StackStorm/fabric.git
#
