# fabrikate-keyvault-flexvolume

### Installing fabrikate-keyvault-flexvolume

1. In your stack's `component.json`, include `fabrikate-keyvault-flexvolume`:

```json
{
  "name": "my-cool-stack",
  "subcomponents": [
    {
      "name": "fabrikate-keyvault-flexvolume",
      "source": "https://github.com/microsoft/fabrikate-definitions",
      "path": "definitions/fabrikate-keyvault-flexvolume",
      "method": "git"
    }
  ]
}
```

Or if you're using a `component.yaml`:

```yaml
name: my-cool-stack
subcomponents:
  - name: fabrikate-keyvault-flexvolume
    source: https://github.com/microsoft/fabrikate-definitions
    path: definitions/fabrikate-keyvault-flexvolume
    method: "git"
```

2. In a terminal window, install the stack dependencies:

```
fab install
```

3. In a terminal window, generate the stack:

```
fab generate prod
```

4. Apply the generated stack manifests:

```
kubectl apply -f ./generated/prod/ --recursive
```

## Usage and Configuration

See: https://github.com/azure/kubernetes-keyvault-flexvol#how-to-use
