# Confluent Schema Registry

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [Confluent's Schema Registry](https://github.com/helm/charts/tree/master/incubator/schema-registry) using the incubator helm chart.

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "confluent-schema-registry"
    type: "helm"
    source: "https://kubernetes-charts-incubator.storage.googleapis.com/"
    method: "helm"
    path: "schema-registry"
```

You should configure the schema registry following the [helm chart values.yaml](https://github.com/helm/charts/blob/master/incubator/schema-registry/values.yaml). You should specify `kafka.enabled: false` or else the helm chart will deploy a non-production ready Kafka & Zookeeper instance. By setting `kafka.enabled: false`, you will need to pass in the broker location to the schema registry using `kafkaStore.overrideBootstrapServers`.

```yaml
config:
subcomponents:
  confluent-schema-registry:
    namespace: "kafka"
    injectNamespace: true
    config:
      replicaCount: 3
      kafkaStore:
        overrideBootstrapServers: "PLAINTEXT://kafka-brokers.kafka:9092"
      kafka:
        enabled: false
```
