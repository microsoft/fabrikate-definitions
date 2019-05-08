# velero

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [Velero](https://github.com/heptio/velero).  

## Usage

Follow the [Velero instructions](https://heptio.github.io/velero/v0.11.0/install-overview) for installing Velero and collect for the configuration you need to use Velero on your target cloud platform.

For example, for the Azure cloud platform you will need to apply the following configuration to Velero as part of a config file (where `velero` is the subcomponent):

```
velero:
  config:
    azure:
      clientId: <client id>
      clientSecret: <client secret>
      subscriptionId: <subscription id>
      tenantId: <tenant id>

      storageResourceGroup: <backup storage resource group>
      storageAccount: <storage account>
      container: <storage container>
```
