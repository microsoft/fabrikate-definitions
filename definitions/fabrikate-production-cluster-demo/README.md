# Fabrikate Production Demo

[![Build Status](https://dev.azure.com/epicstuff/fabrikate-production-cluster-demo-gitops/_apis/build/status/Microsoft.fabrikate-production-cluster-demo?branchName=master)](https://dev.azure.com/epicstuff/fabrikate-production-cluster-demo-gitops/_build/latest?definitionId=58&branchName=master)

This is production demo of what a cluster level Fabrikate High-Level-Definition (HLD) might look like. You can view applications presented by the demo cluster here: https://demo.jack5on.io/productpage.

It includes:

- [Cloud-Native](https://github.com/timfpark/fabrikate-cloud-native/) - Our standardized set of in-cluster monitoring tools.
- [BookInfo](https://github.com/evanlouie/fabrikate-bookinfo/) - A sample multi-language microservices based application.
- Jaeger Hotrod - A sample application used to demonstrate Jaeger tracing.

# Deploy it yourself

If you'd like to run this set of applications youself, please refer to our [documentation](./DIY.md).

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
