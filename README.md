# fabrikate-kafka

Sample Fabrikate Components for Kafka on AKS. This repository sets up the following Fabrikate components:

* Strimzi Kafka Operator
* Confluent Schema Registry
* Prometheus & Grafana
* [Stork & Portworx](/portworx-manual/Portworx.md) (Disabled by Default)

It also sets up a default scalable Kafka Cluster configuration (see [manifests/kafka-cluster.yaml](./manifests/kafka-cluster.yaml)) with persistent volumes, three replicas and TLS mutual authentication.

It also includes Kubernetes network policies to restrict traffic to the Kafka cluster (see [manifests/kafka-networkpolicy.yaml](./manifests/kafka-networkpolicies.yaml)). Only TLS traffic is permitted to the Kafka cluster. Plaintext is only permitted for the Confluent Schema Registry app.

## Perf Tests

A perftest is also included with the repo. This perf test creates clients within the Kafka namespaces and uses TLS mutual authentication.

## Setting Up Grafana Dashboards

The sample configuration provided does not expose grafana and prometheus metrics through an externally accessible IP. You may choose to create an external IP. Alternatively, you can connect to your cluster and port forward the grafana dashboard.

`kubectl port-forward [POD NAME HERE grafana] -n grafana 3000`

Browse to `localhost:3000/dashboard/import`.

There are three dashboards [Kafka, Kafka Connect and Zookeeper Metrics] included in the `dashboards/` folder. You can either copy paste the content of the json files or use the "Upload .json File".
