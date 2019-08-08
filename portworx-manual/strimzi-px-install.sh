#! /usr/bin/env bash

export AZURE_CLIENT_ID=""
export AZURE_CLIENT_SECRET=""
export AZURE_TENANT_ID=""


echo "Creating namespace kafka"
kubectl create namespace kafka


echo "Installing Portworx"

# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
                                                      --from-literal=AZURE_CLIENT_ID=""\
                                                      --from-literal=AZURE_CLIENT_SECRET=""


# Generate custom specs for your portworx config. By default, the script uses Premium volume types, 150 GB, Auto Data and 
# Management network interfaces with Stork, GUI enabled. To customize this config use the api URL to download a custom yaml
# [https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#]

kubectl apply -f temp-px-deploy/px-gen-spec.yaml

# Check to verify the Portworx Daemonset is successfully running

until kubectl get pods --all-namespaces | grep -E "kube-system(\s){3}portworx.*1\/1\s*Running+"
do
  sleep 10
done

# Create a storage class defining the storage requirements like replication factor, snapshot policy, and performance profile for kafka
kubectl create -f temp-px-deploy/kafka-px-ha-sc.yaml

echo "Installing new Portworx enabled Kafka Brokers"

# Swap following lines if you don't want to use ssl.
#kubectl create -n kafka -f strimzi/simple-kafka.yaml
kubectl create -n kafka -f temp-px-deploy/kafka-tls-px.yaml

kubectl create -n kafka -f temp-px-deploy/kafka-topics.yaml
kubectl create -n kafka -f temp-px-deploy/kafka-users.yaml

# For Kafka testing create a cli to interact with the brokers:
kubectl create -n kafka -f temp-px-deploy/kafkaclient.yaml