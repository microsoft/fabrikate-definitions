# fabrikate-istio

> Requires at least [0.1.4](https://github.com/microsoft/fabrikate/releases) or later of [Fabrikate](https://github.com/microsoft/fabrikate).

IMPORTANT NOTE:  This component is depreciated in favor of [Linkerd](../linkerd)

## Common Configs

Custom chart changes:

| Setting                      | Value     | Description                          |
| ---------------------------- | --------- | ------------------------------------ |
| global.proxy.includeIPRanges | "0.0.0.0" | Allows all egress traffic by default |
