#!/usr/bin/bash

echo "Download openshift client (oc, kubectl)..."
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz
tar xvfz openshift-client-linux.tar.gz


echo "Download OpenShift Client, stable release..."
wget https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz
tar xvfz openshift-install-linux.tar.gz


echo "Download nmstatectl tar file from GitHub..."
wget  https://github.com/nmstate/nmstate/releases/download/v2.2.44/nmstate-2.2.44.tar.gz
tar xvfz nmstate-2.2.44.tar.gz

echo "Move nmstatectl to /usr/local/bin..."
sudo mv nmstate-2.2.44/nmstatectl /usr/local/bin/
echo "Make nmstatectl executable..."
sudo chmod +x /usr/local/bin/nmstatectl

