#!/bin/bash
tail -f /var/log/supervisor/mongodb.self.log  | grep  --line-buffered  '^.*$' | #
	while read x ; do \
		echo  -ne  "[STARTING MONGODB] $x \n"; \
		if [[ $x == *"waiting for connections on port 27017"* ]];then \
		  echo "MONGODB RUNNING!"; \
		  ps xu | grep tail | grep -v grep | awk '{ print $2 }'  | xargs kill -9; \
  		  break; \
		fi; \
	done
