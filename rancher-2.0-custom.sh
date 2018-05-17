#!/bin/bash

while ! curl -k https://localhost/ping; do sleep 3; done

# Login
LOGINRESPONSE=`curl -s 'https://127.0.0.1/v3-public/localProviders/local?action=login' -H 'content-type: application/json' --data-binary '{"username":"admin","password":"admin"}' --insecure`
LOGINTOKEN=`echo $LOGINRESPONSE | jq -r .token`

# Change password
curl -s 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"currentPassword":"admin","newPassword":"thisisyournewpassword"}' --insecure

# Create API key
APIRESPONSE=`curl -s 'https://127.0.0.1/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"automation"}' --insecure`
# Extract and store token
APITOKEN=`echo $APIRESPONSE | jq -r .token`

# Configure server-url
RANCHER_SERVER='https://your_rancher_server_address'
curl -s 'https://127.0.0.1/v3/settings/server-url' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" -X PUT --data-binary '{"name":"server-url","value":"'$RANCHER_SERVER'"}' --insecure

# Create cluster
CLUSTERRESPONSE=`curl -s 'https://127.0.0.1/v3/cluster' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"cluster","nodes":[],"rancherKubernetesEngineConfig":{"ignoreDockerVersion":true},"name":"yournewcluster"}' --insecure`
# Extract clusterid to use for generating the docker run command
CLUSTERID=`echo $CLUSTERRESPONSE | jq -r .id`

# Specify role flags to use
ETCD-ROLEFLAG="--etcd"
CONTROLLER-ROLEFLAG="--controlplane"
WORKER-ROLEFLAG="--worker"

# Generate token (clusterRegistrationToken) and extract nodeCommand
AGENTCOMMAND=`curl -s 'https://127.0.0.1/v3/clusterregistrationtoken' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' --insecure | jq -r .nodeCommand`

# Show the command for ETCD NODES
echo "${AGENTCOMMAND} ${ETCD-ROLEFLAG}" 

# Show the command for CONTROLLER NODES
echo "${AGENTCOMMAND} ${CONTROLLER-ROLEFLAG}"

# Show the command for WORKER NODES
echo "${AGENTCOMMAND} ${WORKER-ROLEFLAG}"
