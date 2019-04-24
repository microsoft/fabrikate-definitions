# Fabrikate-Prometheus-Grafana

This [fabrikate](http://github.com/microsoft/fabrikate) stack installs Prometheus and Grafana on your cluster.

### Prometheus Rules and Alerts

Rules and alerts for prometheus are defined in the `common.yaml` file as part of the `serverFiles` setting.

The rules and alers were extracted from the [`prometheus-rules.yaml`](https://github.com/coreos/prometheus-operator/blob/011588800c45beb9e421936b547b15a4bc88e134/contrib/kube-prometheus/manifests/prometheus-rules.yaml) file that is part of the [prometheus-operator](https://github.com/coreos/prometheus-operator) project from [CoreOS](https://coreos.com/). Some of the rules and alerts were excluded because they referred deprecated metrics or were tracking components that need to be specifically installed such as prometheus-operator.

**Note:** Some rules and alerts were modified and tested that they work in an Azure Kubernetes Service (AKS) cluster. Currently they haven't been verified in other cluster environments.

#### Prometheus Sending Alerts

Prometheus can be configured to send alerts to different clients: Email, PagerDuty, Slack etc. More information about sending alerts is available in the Prometheus [Alerting Overview](https://prometheus.io/docs/alerting/overview/).

##### Slack Notifications

Requirements:

- Create a [Slack Webhook](https://api.slack.com/incoming-webhooks) where notifications will be sent to.

In `common.yaml`, add the `alertmanagerFiles` section under the prometheus config. Update the values with the information from your Slack App.

More information about these settings is available in the [Notification Template Examples](https://prometheus.io/docs/alerting/notification_examples/) from Prometheus.

```
alertmanagerFiles:
  alertmanager.yml:
    global:
      slack_api_url: '<slack_webhook_url>'
    receivers:
    - name: default-receiver
      slack_configs:
        - channel: '#mychannel'
          text: '{{ range .Alerts }}{{ .Labels.instance }} {{ end }} Message: {{ .CommonAnnotations.message }}'
          send_resolved: true
    route:
      group_wait: 10s
      group_interval: 5m
      receiver: default-receiver
      repeat_interval: 5m
```
