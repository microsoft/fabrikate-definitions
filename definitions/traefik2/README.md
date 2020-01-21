# Traefik 2

A wrapper Fabrikate component for the official
[Containous Traefik2 Helm Chart](https://github.com/containous/traefik-helm-chart)

> Note: the underlying helm chart provided from Containous is still in
> **incubator** status. It is **not recommended** to use in production. However
> if you do wish to use this component, ensure you thoroughly test with and
> deploy a specific version of the helm chart by specifying/pinning a `version`
> of the chart with a specific SHA (eg.
> `version: d7fc8d82551dd8c22a842948f32f4dc9233492e7`) -- As a `version` is not
> currently specified, it will pull `master`.

## Pinning a version

Although useful for development purposes, this component does not pin any
specific `version` of the helm chart to consume (defaults to `master`). As a
precaution, it is recommended to pin the underlying Traefik 2 helm chart to a
specific SHA as it is still in incubator status and parts of it can change at
any time.

An example of a pinned version of the component:

```yaml
name: fabrikate-traefik2
subcomponents:
  - name: traefik2
    type: helm
    source: https://github.com/containous/traefik-helm-chart
    version: d7fc8d82551dd8c22a842948f32f4dc9233492e7
    method: git
    path: traefik
    branch: master
```
