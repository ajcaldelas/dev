# OpenShift install instructions

## Pre-reqs
- Have a DNS entry for the cluster 
  - API: `api.<cluster-name>.<base domain>`
  - Ingress: `*.apps.<cluster-name>.<base domain>`

## Install 
1. Run the setup script that will download the install tool and client
2. Run the OCP Instal script, this will generate the agent ISO needed for installing the cluster

## Optional Steps   
1. The scripts directory contains
