# fabrikate-kafka

Sample Fabrikate Components for Kafka on AKS. This repository sets up the following Fabrikate components:

* Strimzi Kafka Operator
* Confluent Schema Registry
* Prometheus & Grafana
* Stork & Portworx

It also sets up a default scalable Kafka Cluster configuration (see [manifests/kafka-cluster.yaml](./manifests/kafka-cluster.yaml)) with persistent volumes, three replicas and TLS mutual authentication.

It also includes Kubernetes network policies to restrict traffic to the Kafka cluster (see [manifests/kafka-networkpolicy.yaml](./manifests/kafka-networkpolicies.yaml)). Only TLS traffic is permitted to the Kafka cluster. Plaintext is only permitted for the Confluent Schema Registry app.

## Perf Tests

A perftest is also included with the repo. This perf test creates clients within the Kafka namespaces and uses TLS mutual authentication.

## Setting Up Grafana Dashboards

The sample configuration provided does not expose grafana and prometheus metrics through an externally accessible IP. You may choose to create an external IP. Alternatively, you can connect to your cluster and port forward the grafana dashboard.

`kubectl port-forward [POD NAME HERE grafana] -n grafana 3000`

Browse to `localhost:3000/dashboard/import`.

There are three dashboards [Kafka, Kafka Connect and Zookeeper Metrics] included in the `dashboards/` folder. You can either copy paste the content of the json files or use the "Upload .json File".

## Setting up Portworx *Unstable*

To configure you Portworx Virtualization layer with Strimzi, follow the following steps:

```
# Create a secret to give Portworx access to Azure APIs
kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID="" \
                                                      --from-literal=AZURE_CLIENT_ID=""\
                                                      --from-literal=AZURE_CLIENT_SECRET=""


# Generate custom specs for your portworx config. By default, the script uses Premium volume types, 150 GB, Auto Data and 
# Management network interfaces with Stork, GUI enabled. To customize this config use the api URL to download a custom yaml
# [https://docs.portworx.com/portworx-install-with-kubernetes/cloud/azure/aks/2-deploy-px/#]

kubectl apply -f 'https://aks-install.portworx.com/2.1?mc=false&kbver=1.12.7&b=true&s=%22type%3DPremium_LRS%2Csize%3D150%22&j=auto&md=type%3DPremium_LRS%2Csize%3D100&c=px-cluster-4148c550-39b2-4954-8a15-fa0cfe584dd8&aks=true&stork=true&lh=true&st=k8s'

until kubectl get pods --all-namespaces | grep -E "kube-system(\s){3}portworx.*1\/1\s*Running+"
do
  sleep ${wait}
donefg

# Create a storage class defining the storage requirements like replication factor, snapshot policy, and performance profile for kafka
kubectl create -f perftest/kafka-px-ha-sc.yaml

echo "Installing Kafka"

# Swap following lines if you don't want to use ssl.
kubectl create -n kafka -f perftest/simple-kafka.yaml
#kubectl create -n kafka -f perftest/tls-kafka.yaml

kubectl create -n kafka -f perftest/kafka-topics.yaml
kubectl create -n kafka -f perftest/kafka-users.yaml

### Kafka Perf test:
kubectl create -n kafka -f perftest/kafkaclient.yaml
```
