# MinIO

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [MinIO](https://github.com/MinIO/MinIO).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "minio"
    source: "https://github.com/microsoft/fabrikate-definitions.git"
    path: "definitions/minio"
    method: "git"
```

### Setting Up MinIO

Extensive documentation exists at the [Helm Charts repo](https://github.com/helm/charts/tree/master/stable/MinIO). If you are running MinIO on AKS, it is recommended you change the PVC default storage class to managed premium for production workloads:

```yaml
minio:
  persistence:
    storageClass: "managed-premium"
```

TLS is also not enabled by default so it is recommended you enable TLS to secure calls to MinIO in the cluster.

### Accessing the MinIO Browser

You can easily access the MinIO browser without attaching an external IP to the cluster by port forwarding. You must either keep the default `environment` configuration or set it to `MINIO_BROWSER: "on"` for the MinIO browse app to exist.

1. Get the pod name by executing `kubectl get po -n minio`
2. Run `kubectl port-forward -n minio <POD_NAME> 9000:9000`
3. Browse to `localhost:9000` in your web browser to access the MinIO browser.

In general, you should set `MINIO_BROWSER: "off"` for improved security.
