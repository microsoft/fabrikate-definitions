# Fabrikate Definitions

> An aggregated and curated collection of Fabrikate definitions/components

[![Build Status](https://dev.azure.com/epicstuff/fabrikate-definitions/_apis/build/status/Microsoft.fabrikate-definitions?branchName=master)](https://dev.azure.com/epicstuff/fabrikate-definitions/_build/latest?definitionId=65&branchName=master)

Here you can find a curated listed of [Fabrikate](https://github.com/microsoft/fabrikate) definitions
which you can use as components for your Kubernetes cluster.

## Requirements

[Fabrikate](https://github.com/microsoft/fabrikate) >= 0.5.2

## Example Usage

This repository acts as an aggregation repository of commonly used Fabrikate definitions; some
definitions utilize other definitions defined within this repository. As such, to utilize a definition
from here, you should define your components [`source`](https://github.com/microsoft/fabrikate/blob/master/docs/component.md)
as this git repository and use the [`path`](https://github.com/microsoft/fabrikate/blob/master/docs/component.md)
argument as the relative path to the target component itself.

In this example we'll deploy the
[cloud-native](https://github.com/microsoft/fabrikate-definitions/tree/master/definitions/fabrikate-cloud-native)
infrastructure stack and
[Istio's BookInfo application](https://github.com/microsoft/fabrikate-definitions/tree/master/definitions/fabrikate-bookinfo)
components to simulate what a full production cluster component may look like.

Define your top level cluster definitions as such:

```yaml
name: my-cluster
subcomponents:
  - name: cloud-native # In-cluster monitoring and service-mesh tooling
    source: https://github.com/microsoft/fabrikate-definitions.git
    path: definitions/fabrikate-cloud-native
    method: git
  - name: bookinfo # Istio BookInfo application - wrapped in Fabrikate component
    source: https://github.com/microsoft/fabrikate-definitions.git
    path: definitions/fabrikate-bookinfo
    method: git
```

# Contributing

This project welcomes contributions and suggestions. Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
