# fabrikate-kafka

Sample Fabrikate Components for Kafka on AKS. This repository sets up the following Fabrikate components:

* Strimzi Kafka Operator
* Confluent Schema Registry

It also sets up a default scalable Kafka Cluster configuration (see [manifests/kafka-cluster.yaml](./manifests/kafkacluster.yaml)) with persistent volumes, three replicas and TLS mutual authentication.

It also includes Kafka network policies to restrict traffic to the Kafka cluster (see [manifests/kafka-networkpolicy.yaml](./manifests/kafka-networkpolicy.yaml)). Only TLS traffic is permitted to the Kafka cluster from outside the `kafka` namespace. Any traffic from within the namespace is currently permitted. **Note: The network policies are still a work in progress. You will have to manually apply them post install.**

Currently, only KafkaUsers created within the `kafka` namespaces will have secrets and certificates generated for them. This is done on purpose as only the administrations with access to the `kafka` namespace will be allowed to add or delete Kafka Users.

## Perf Tests

A perftest is also included with the repo. This perf test creates clients within the Kafka namespaces and uses TLS mutual authentication.
