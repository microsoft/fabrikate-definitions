# Velero

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [ECK-Elastic Cloud on Kubernetes](https://github.com/elastic/cloud-on-k8s).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "elasticsearch-operator"
    type: static
    source: "https://download.elastic.co/downloads/eck/0.9.0/all-in-one.yaml"
    method: "remote-url"
```

# Elastic Cloud on Kubernetes - ECK

ECK (Elastic Cloud on Kubernetes) encompasses the Elasticsearch operator.

## Deploy ECK

1. Monitor the operator logs

> `kubectl -n elastic-system logs -f statefulset.apps/elastic-operator`


2. Deploy Elasticsearch

> `kubectl -n elasticsearch apply -f manifests/eck-cluster.yaml`


This sample cluster may be already applied.


More information about deploying ECK can be found [here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html#k8s-deploy-eck)

### Verify elasticsearch
You can verify the deployment succeeded by calling the elasticsearch API.

1. Fetch the elasticsearch password
> `kubectl -n elasticsearch get secret quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode`


2. Portforward
> `kubectl -n elasticsearch port-forward service/quickstart-es-http 9200`

3. Call the endpoint
> `curl -u "elastic:<password>" -k "https://localhost:9200"`