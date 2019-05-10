# Velero

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [Velero](https://github.com/heptio/velero).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "velero"
    source: "https://github.com/sayar/fabrikate-velero"
    method: "git"
```

For the Azure cloud platform you will need to apply the following configuration to Velero as part of a config file (where `velero` is the subcomponent):

```yaml
velero:
  config:
    credentials:
      useSecret: true
      secretContents:
        AZURE_SUBSCRIPTION_ID: <subscription id>
        AZURE_TENANT_ID: <tenant id>
        AZURE_CLIENT_ID: <client id>
        AZURE_CLIENT_SECRET: <client secret>
    configuration:
      provider: "azure"
      backupStorageLocation:
        name: "azure"
        bucket: <blob container name>
        config:
          resourceGroup: <azure resource group name>
          storageAccount: <azure storage account name>
      volumeSnapshotLocation:
        name: "azure"
        config: {}
```

To add an hourly scheduled backup for a specific namespace (for example prometheus), append the following to your velero.config.

```yaml
schedules:
  hourly-prometheus-backup:
    schedule: "0 * * * *"
    template:
      includedNamespaces:
      - "*"
      labelSelector:
        matchLabels:
          namespace: "prometheus"
      snapshotVolumes: true
      ttl: "720h0m0s"
```