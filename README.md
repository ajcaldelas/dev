# OpenShift install instructions

## Pre-reqs

- Have a DNS entry for the cluster 

  - API: `api.<cluster-name>.<base domain>`

  - Ingress: `*.apps.<cluster-name>.<base domain>`

  - Run `dig +short api.<cluster-name>.<base domain>` to check for the API VIP entry

  - example `dig +short api.sno.oset.amd.com`

  - Run `dig +short test.apps.<cluster-name>.<base domain>` to check for the ingress entry, needs to be a wildcard entry

  - example `dig +short test.apps.sno.oset.amd.com`

- Need to have `NMStatectl` installed on the bastion host that is running these scripts

## Install

1. Run the setup script that will download the install tool and client. It will also will grab the nmstatectl tar file
   `./setup.sh`

2. Modify the Agent Config YAML, this is a requirement. You need to define the nodes in the system which includes the NIC info and NManager settings via nmstatectl. Use the sample in this directory to fill out the rest. The RendevousIP is the IP that acts as the bootstrap node. Select a node and use that IP for the RendevousIP.

3. Modify the Install config, you MUST include the following:
  
  - API VIP and the Ingress VIP

  - Cluster Name

  - MachineNetwork needs to match the subnet you will have the machines on

  - The Pull Secret

  - Authorized SSH Keys for node access

3. Run the OCP Install script, this will generate the agent ISO needed for installing the cluster. The iso is located under install/agent.x86_64.iso. This script will also attempt to copy the ISO to a web server. Change the script to reflect this
  `./ocp-install.sh`

4. Mount the ISOs onto the virtual media servers.

## Mounting

1. The scripts directory contains scripts directory to setup lenovo boxes, you will need to mount the ISO manually or set up the remote virtual media manually.

2. To run any of the redfish scripts you need to export the `REDFISH_USER` and `REDFISH_PASSWORD`
    a. these scripts assume they all use the same user, so make sure this matches up or the scripts will fail

3. Run the `REDFISH_USER=<user> REDFISH_PASSWORD=<password> redfish-shutdown.sh`

4. Run the `REDFISH_USER=<user> REDFISH_PASSWORD=<password> redfish-cleanup.sh`

5. Run the `REDFISH_USER=<user> REDFISH_PASSWORD=<password> redfish-virtual-media.sh`

TODOs: Need to add redfish setup for iDRACs
