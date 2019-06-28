# MinIO

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "kafka"
    source: "https://github.com/microsoft/fabrikate-definitions.git"
    path: "definitions/strimzi-kafka-operator"
    method: "git"
```

You can apply the operator to watch a specific namespace instead of the default namespace by including the following configuration if your fabrikate config yaml (e.g. common.yaml).

```yaml
config:
subcomponents:
  kafka:
    namespace: "kafka"
    injectNamespace: true
```
