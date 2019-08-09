# Elasticsearch Filebeat Kibana

This [fabrikate](https://github.com/microsoft/fabrikate) component installs the following components in your cluster:

- [Elasticsearch](https://www.elastic.co/products/elasticsearch)
- [Filebeat](https://www.elastic.co/products/beats/filebeat)
- [Kibana](https://www.elastic.co/products/kibana)

By default, it enables the filebeat [kubernetes provider](https://www.elastic.co/guide/en/beats/filebeat/current/configuration-autodiscover.html) which watches for Kubernetes pods to start, update and stop. The component is also configured in `common.yaml` to output logs to elastic search.

Filebeat supports various ways for monitoring and forwarding logs. Check the [official documentation](https://www.elastic.co/products/beats/filebeat) for more information on the different options.

### Requirements

- The [fabrikate](http://github.com/microsoft/fabrikate/releases) cli tool installed locally
- The [helm](https://github.com/helm/helm/releases) cli tool installed locally
- The kubectl cli tool installed locally

### Installing elk

1. In a terminal window, install the stack dependencies:

```
fab install
```

2. In a terminal window, generate the stack:

```
fab generate prod
```

3. Apply the generated stack manifests:

```
kubectl apply -f ./generated/prod/ --recursive
```

### License

MIT
