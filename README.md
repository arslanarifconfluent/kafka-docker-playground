# kafka-docker-playground

Playground for Kafka/Confluent Docker experimentations

## Connectors:

### Source

* [AWS S3 Source](connect-s3-source/README.md)
* [AWS Kinesis Source](connect-kinesis-source/README.md)
* [AWS SQS Source](connect-sqs-source/README.md) [also with [SASL_SSL](connect-sqs-source/README.md#with-sasl_ssl-authentication) and [SSL](connect-sqs-source/README.md#with-ssl-authentication) authentication]
* [JDBC MySQL Source](connect-jdbc-source/README.md#MySQL)
* [Debezium MySQL source](connect-debezium-source/README.md#MySQL)
* [Debezium PostgreSQL source](connect-debezium-source/README.md#PostgreSQL)
* [IBM MQ Source](connect-ibm-mq-source/README.md)
* [Solace Source](connect-solace-source/README.md)
  
### Sink

* [HDFS 2 Sink](connect-hdfs-sink/README.md)
* [AWS S3 Sink](connect-s3-sink/README.md)
* [Elasticsearch Sink](connect-elasticsearch-sink/README.md)
* [HTTP Sink](connect-http-sink/README.md)
* [GCP BigQuery Sink](connect-gcp-bigquery-sink/README.md)
* [GCS Sink](connect-gcs-sink/README.md) [also with [SASL_SSL](connect-gcs-sink/README.md#with-sasl_ssl-authentication), [SSL](connect-gcs-sink/README.md#with-ssl-authentication) and [Kerberos GSSAPI](connect-gcs-sink/README.md#with-kerberos-gssapi-authentication) authentication]
* [Solace Sink](connect-solace-sink/README.md)
  
## Confluent Cloud:

* [ccloud demo](ccloud-demo/README.md)


## Deployments

* [PLAINTEXT](plaintext/README.md): no security
* [SASL_SSL](sasl-ssl/README.md): SSL encryption / SASL_SSL or 2 way SSL authentication
* [Kerberos](kerberos/README.md): no SSL encryption / Kerberos GSSAPI authentication
* [SSL_Kerberos](ssl_kerberos/README.md) SSL encryption / Kerberos GSSAPI authentication

## Other:

* [Confluent Rebalancer](rebalancer/README.md)

## Other useful resources

* [A Kafka Story](https://github.com/framiere/a-kafka-story): A step by step guide to use Kafka ecosystem (Kafka Connect, KSQL, Java Consumers/Producers, etc..) with Docker
* [Kafka Security playbook](https://github.com/Dabz/kafka-security-playbook): demonstrates various security configurations with Docker
* [MDC and single views](https://github.com/framiere/mdc-with-replicator-and-regexrouter): Multi-Data-Center setup using Confluent [Replicator](https://docs.confluent.io/current/connect/kafka-connect-replicator/index.html)