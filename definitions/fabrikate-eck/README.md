# Elastic Cloud on Kubernetes - (ECK)

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates
the Kubernetes resource manifests for
[ECK-Elastic Cloud on Kubernetes](https://github.com/elastic/cloud-on-k8s). ECK
(Elastic Cloud on Kubernetes) encompasses the Elasticsearch operator.

## Usage

For customizing your elasticsearch cluster, modify the
[common.yaml](config/common.yaml) config with your own configuration.

## Deploy ECK

1. Modify the Elasticsearch to your configuration
2. `fabrikate install`
3. `fabrikate generate`
4. `kubectl apply -f ./generated`; note: you may need to run this multiple times
   so the CRD's have time to populate your cluster.

A quickstart sample cluster is deployed by default.

More information about deploying ECK can be found
[here](https://www.elastic.co/guide/en/cloud-on-k8s/current/k8s-quickstart.html#k8s-deploy-eck)

## Verify elasticsearch

You can verify the deployment succeeded by calling the elasticsearch API.

1. Fetch the elasticsearch password
   - `kubectl -n elasticsearch get secret elasticsearch-fabrikate-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode`
2. Portforward
   - `kubectl -n elasticsearch port-forward service/elasticsearch-fabrikate-es-http 9200`
3. Call the endpoint
   - `curl -u "elastic:<password>" -k "https://localhost:9200"`
4. Monitor the operator logs
   - `kubectl -n elastic-system logs -f statefulset.apps/elastic-operator`
