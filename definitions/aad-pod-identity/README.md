# Azure Active Directory - Pod Identity

This [fabrikate](https://github.com/microsoft/fabrikate) component installs [aad-pod-identity](https://github.com/Azure/aad-pod-identity) on your cluster.

### Requirements

- The [fabrikate](http://github.com/microsoft/fabrikate/releases) cli tool installed locally
- The [helm](https://github.com/helm/helm/releases) cli tool installed locally
- The kubectl cli tool installed locally

#### Optional requirements for helper script

- [azure-cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/)
- [yq](https://github.com/mikefarah/yq#install)

### Installing aad-pod-identity

1. In a terminal window, install the stack dependencies:

```
fab install
```

2. In a terminal window, run the helper script:

This script looks in a resource group for Managed Identities and merges them into the config file of your choosing. If no config argument is given it will default to `./config/common.yaml`

#### Usage
```
./scripts/get-pod-identities.sh <resource-group-name> <config-file-name>
```

#### Example
```
./scripts/get-pod-identities.sh rg-bedrock-azure-mi ./config/common.yaml
```

3. In a terminal window, generate the stack:

```
fab generate prod
```

4. Apply the generated stack manifests:

```
kubectl apply -f ./generated/prod/ --recursive
```
