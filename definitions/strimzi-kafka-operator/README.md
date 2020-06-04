# Strimzi Kafka Operator

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "strimzi-kafka-operator"
    type: "helm"
    path: "strimzi-kafka-operator"
    method: "helm"
    source: "http://strimzi.io/charts/"
```

You can apply the operator to watch a specific namespace instead of the default namespace by including the following configuration if your fabrikate config yaml (e.g. common.yaml).

```yaml
config:
subcomponents:
  kafka:
    namespace: "kafka"
    injectNamespace: true
```
