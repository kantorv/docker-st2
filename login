#!/bin/bash
SSH_OPTS="-o StrictHostKeyChecking=no -o IdentitiesOnly=yes"
CONT_IP=$(sudo docker inspect st2_cont | grep IPAddress | cut -d '"' -f 4)
ssh  $SSH_OPTS -i docker/sshkey.pem  root@$CONT_IP




