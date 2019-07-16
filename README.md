# fabrikate-kafka

Sample Fabrikate Components for Kafka on AKS. This repository sets up the following Fabrikate components:

* Strimzi Kafka Operator
* Confluent Schema Registry

It also sets up a default scalable Kafka Cluster configuration (see [manifests/kafka-cluster.yaml](./manifests/kafka-cluster.yaml)) with persistent volumes, three replicas and TLS mutual authentication.

It also includes Kubernetes network policies to restrict traffic to the Kafka cluster (see [manifests/kafka-networkpolicy.yaml](./manifests/kafka-networkpolicies.yaml)). Only TLS traffic is permitted to the Kafka cluster. Plaintext is only permitted for the Confluent Schema Registry app.

## Perf Tests

A perftest is also included with the repo. This perf test creates clients within the Kafka namespaces and uses TLS mutual authentication.
