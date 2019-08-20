# Kafka Connect

As part of the Fabrikate Kafka component, Kafka Connect is installed. You can find the configuration under manifests/kafka-connect.yaml. This is part of the [Kafka Connect Strimzi](https://strimzi.io/docs/master/#kafka-connect-str) implementation.

Sample `kafka-connect.yaml`:
```
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaConnect
metadata:
  name: kconnect-cluster
  labels:
    app: kconnect-cluster
spec:
  version: 2.2.1
  replicas: 1
  bootstrapServers: kcluster-kafka-bootstrap:9093
  image: edsa14/mongo-kafka-connect:v2
  authentication:
    type: tls
    certificateAndKey: 
      certificate: user.crt
      key: user.key
      secretName: kafka-connect-user
  tls:
    trustedCertificates:
      - secretName: kcluster-cluster-ca-cert
        certificate: ca.crt
```

This project includes an sample Kafka Connect [Sink Connector](https://docs.confluent.io/current/connect/index.html) using [mongoDB](https://www.mongodb.com).

## Running the mongoDB connector
To run the sample connector you'll need to create a mongoDB cluster by following these [instructions](https://docs.mongodb.com/manual/tutorial/atlas-free-tier-setup/#create-free-tier-manual)

Once you have created a cluster, you'll need to create:
- A database
- A collection

For the above, follow the [Getting Started](https://docs.atlas.mongodb.com/getting-started/) instructions.

##### MongoDB Network Access
Enable all network access by going to. The **Network Access** Tab, click the Add IP Address button and select all. This should populate `0.0.0.0` in the allowed IP addresses table.

<img src="images/mongodb-network.png?sanitize=true">

### Setup a Kafka topic
The sink connector will take data from a Kafka topic and store it in mongoDB. For this example, you can use the `examples/kafka_connect/kafka-topics.yaml` to setup a topic. In this case we will be getting data from the `kconnect-mongodb-topic`.

`kafka-topics.yaml`:
```
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: kconnect-mongodb-topic
  namespace: kafka
  labels:
    strimzi.io/cluster: kcluster
spec:
  partitions: 6
  replicas: 1
  config:
    retention.ms: 7200000
    segment.bytes: 1073741824
```

Create the topic in the Kubernetes cluster:
```
kubectl apply -n kafka -f examples/kafka_connect/kafka-topics.yaml
```

### Create the MongoDB Connector
Kafka Connect comes with a REST API that can be used to create and update connectors.
You can test the API by doing a port-forward:
`kubectl -n kafka port-forward kconnect-cluster-connect-679d68f9fb-4lrz8 8083:8083`

Under `connectors/mongoDBSink/CreateMongoSinkConnector.json` you'll find the following:
```
{"name": "mongo-sink-connector",
    "config": {
        "topics": "kconnect-mongodb-topic",
        "connector.class": "com.mongodb.kafka.connect.MongoSinkConnector",
        "tasks.max": "1",
        "key.converter": "org.apache.kafka.connect.json.JsonConverter",
"key.converter.schema.registry.url": "http://localhost:8081",
"value.converter": "org.apache.kafka.connect.json.JsonConverter",
"value.converter.schema.registry.url": "http://localhost:8081",
"value.converter.schemas.enable": "false",
"connection.uri": "mongodb+srv://<username>:<password>@<cluster>/<database>",
"database": "<my-database>",
"collection": "<my-collection>",
"max.num.retries": "3",
"retries.defer.timeout": "5000",
"key.projection.type": "none",
"key.projection.list": "",
"value.projection.type": "none",
"value.projection.list": "",
"field.renamer.mapping": "[]",
"field.renamer.regex": "[]",
"document.id.strategy": "com.mongodb.kafka.connect.sink.processor.id.strategy.BsonOidStrategy",
"post.processor.chain": "com.mongodb.kafka.connect.sink.processor.DocumentIdAdder",
"delete.on.null.values": "false",
"writemodel.strategy": "com.mongodb.kafka.connect.sink.writemodel.strategy.ReplaceOneDefaultStrategy",
"max.batch.size ": "0",
"rate.limiting.timeout": "0",
"rate.limiting.every.n": "0",
"topic.override.sourceB.collection": "sourceB",
"topic.override.sourceB.document.id.strategy": "com.mongodb.kafka.connect.sink.processor.id.strategy.ProvidedInValueStrategy"
}} 
```
You **must** change at least the following variables:

| Variable  | Description | Example |
| ------------- | ------------- | ------------- |
| name | the name of the connector | `mongo-sink-connector` |
| connection.uri | the connection string for mongodb | `mongodb+srv://<username>:<password>@<cluster>/<database>`|
| database | the name of your database on MongoDB | `kafka-db` |
| collection | the name of your collection in MongoDB | `kafka` |

More information on the settings can be found on the [MongoDB Kafka sink connector guide](https://github.com/mongodb/mongo-kafka/blob/master/docs/sink.md).

After updating the settings, create the connector:
```
curl -H 'Content-Type: application/json' -X POST -d @/home/examples/connectors/mongoDBSink/CreateMongoSinkConnector.json http://localhost:8083/connectors
```

Verify the connector is created on `localhost:8083/connectors`.

##### Update an existing connector

In `examples/kafka_connect/connectors/mongoDBSink/UpdateMongoSinkConnector.json` you'll find the `json` structure to update the settings on the mongoDB sink connector. Change the settings in this file.

To update the connector:
```
curl -H 'Content-Type: application/json' -X PUT -d @/home/examples/connectors/mongoDBSink/UpdateMongoSinkConnector.json http://localhost:8083/connectors/mongo-sink-connector/config
```

You can swap `mongo-sink-connector` in the URL with the corresponding name of the connector you created.

To verify the changes were applied:
```
localhost:8083/connectors/mongo-sink-connector/config
```

To check the status of the connector:
```
localhost:8083/connectors/mongo-sink-connector/status
```

### Add sample data to Kafka
Sample data can be added to Kafka via the Kafka Client.

Sample Message:
```
{"propertyA": "A", "propertyB": "B"}
```

To add a message in the `kconnect-mongodb-topic` topic:
```
kubectl -n kafka exec -ti kcluster-kafka-0 -- bin/kafka-console-producer.sh --broker-list kcluster-kafka-brokers.kafka:9092 --topic kconnect-mongodb-topic
```

This will launch an interative command prompt:
1. Paste the Sample Message from above
2. Type Ctrl+C to exit

### Troubleshooting the Connector
Check the status of the connector to see if there were any errors:
```
localhost:8083/connectors/mongo-sink-connector/status
```

## Kafka Connect Docker Image
For this example, the [edsa14/mongo-kafka-connect](https://hub.docker.com/r/edsa14/mongo-kafka-connect) docker image containing the MongoDB Connector was created. This image is specified. For reference, the Dockerfile used to create this image is in the `examples` directory. To run the example, you can refer to this image. 

This examples uses the [mongodb/mongo-kafka](https://www.confluent.io/hub/mongodb/kafka-connect-mongodb) connector.

If you want to use a different kind of connector, follow the instructions below to create an image that contains the desired connector.

Connectors are a set of `jar` files. To create a docker image with a connector you need to:
1. Download the connector jar files
2. Copy the connector files

Copying the connector files is done in the Dockerfile:
```
FROM strimzi/kafka:0.12.0-kafka-2.2.1
USER root:root
COPY ./my-plugins/ /opt/kafka/plugins/
USER 1001
```