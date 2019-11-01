# Fabrikate-Linkerd

This [fabrikate](https://github.com/microsoft/fabrikate) component installs [Linkerd2](https://linkerd.io/2/overview/) on your cluster.

### Requirements

- The [fabrikate](http://github.com/microsoft/fabrikate/releases) cli tool installed locally
- The [helm](https://github.com/helm/helm/releases) cli tool installed locally
- The kubectl cli tool installed locally

### Installing fabrikate-linkerd

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
