# KEDA

This [Fabrikate](https://github.com/microsoft/fabrikate) definition generates the Kubernetes resource manifests for [KEDA](https://keda.sh/#).

## Usage

Add the KEDA components to your component.yaml file with the following command:

```
fab add keda --source https://github.com/microsoft/fabrikate-definitions --path definitions/keda
```

Alternatively, manually add the following to your component.yaml:

```yaml
name: kedacluster
type: component
subcomponents:
- name: keda
  type: component
  source: https://github.com/microsoft/fabrikate-definitions
  method: git
  path: definitions/keda
  branch: master

```

### Setting Up KEDA

It is recommended you deploy all KEDA related resources into the 'keda' namespace, which is automatically provisioned into the cluster via this Fabrikate definition.

```yaml
keda:
  namespace: keda
```