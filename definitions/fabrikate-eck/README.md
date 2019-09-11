# Elastic Cloud on Kubernetes - (ECK)

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [ECK-Elastic Cloud on Kubernetes](https://github.com/elastic/cloud-on-k8s). ECK (Elastic Cloud on Kubernetes) encompasses the Elasticsearch operator.

## Usage

For customizing your elasticsearch cluster, modify the quickstart sample in the [eck-cluster.yaml](manifests/eck-cluster.yaml) with your own configuration. The default configuration is listed below:

```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1alpha1
kind: Elasticsearch
metadata:
  name: quickstart
  namespace: elasticsearch
spec:
  version: 7.2.0
  nodes:
  - nodeCount: 1
    config:
      node.master: true
      node.data: true
      node.ingest: true
```

## Deploy ECK

1. Modify the  Elasticsearch to your configuration

> `kubectl -n elasticsearch apply -f manifests/eck-cluster.yaml`


A quickstart sample cluster is deployed by default.

More information about deploying ECK can be found [here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html#k8s-deploy-eck)

## Verify elasticsearch
You can verify the deployment succeeded by calling the elasticsearch API.

1. Fetch the elasticsearch password
> `kubectl -n elasticsearch get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode`


2. Portforward
> `kubectl -n elasticsearch port-forward service/quickstart-es-http 9200`

3. Call the endpoint
> `curl -u "elastic:<password>" -k "https://localhost:9200"`

4. Monitor the operator logs

> `kubectl -n elastic-system logs -f statefulset.apps/elastic-operator`
