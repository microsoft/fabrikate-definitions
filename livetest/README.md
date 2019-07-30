# Kafka Liveness Test

This directory contains a simple test script to check if a Strimzi Operator Kafka cluster is live. 

## Requirements

- A kubernetes cluster with Kafka deployed via Strimzi Operator
- `kubectl` should be configured to point to this cluster

## Running the test

Simply run `sh ./livetest.sh`. The script will create and deploy a kafka client to act as a sample producer and consumer.

The test results will displayed at the end. The script with exit with code 0 for success and 1 for failure.