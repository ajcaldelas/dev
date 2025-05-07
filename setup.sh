#!/usr/bin/bash

echo "Download OpenShift Client, stable release..."
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar xvfz openshift-client-linux.tar.gz

echo "Download openshift client (oc, kubectl)..."
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz
tar xvfz openshift-install-linux.tar.gz

echo "Install nmstatectl on Fedora"
sudo dnf install nmstatectl -y 


