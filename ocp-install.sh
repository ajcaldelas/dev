#!/usr/bin/bash

rm -rf install/

mkdir install

cp agent-config.yaml install-config.yaml install

./openshift-install --dir=install agent create image

sleep 60

# Copy the file to a web server
# TODO: Make this a variable
scp install/agent.x86_64.iso amd@10.216.188.48:~/

# TODO: Add a ssh command to copy the file to the web server directory
