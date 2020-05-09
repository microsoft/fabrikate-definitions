# MetalLB

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [MetalLB](https://github.com/danderson/metallb).

## Usage

Add the following to your component.yaml:

```yaml
subcomponents:
  - name: "metallb"
    source: "https://github.com/microsoft/fabrikate-definitions.git"
    path: "definitions/metallb"
    method: "git"
```

### Setting Up MetalLB

This definition uses Helm for installation and management of MetalLB. Documentation can be found in the [Helm Charts Repo](https://github.com/helm/charts/tree/master/stable/metallb).

It is recommended you change the configuration to suit your own needs. This can be achieved using the `configInLine` stanza in your `common.yaml` like so:

```yaml
metallb:
  config:
    configInLine:
      address-pools:
          - name: default-ip-space
            protocol: layer2
            addresses:
            - 10.0.1.10-10.0.1.99
```
