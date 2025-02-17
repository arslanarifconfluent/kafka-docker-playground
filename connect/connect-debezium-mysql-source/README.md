# Debezium MySQL source connector



## Objective

Quickly test [Debezium MySQL](https://docs.confluent.io/current/connect/debezium-connect-mysql/index.html#debezium-mysql-source-connector) connector.




## How to run

Simply run:

```
$ playground run -f debezium-mysql-source<tab>
```

## Details of what the script is doing


Describing the team table in DB `mydb`

```bash
$ docker exec mysql bash -c "mysql --user=root --password=password --database=mydb -e 'describe team'"
```

Show content of team table:

```bash
$ docker exec mysql bash -c "mysql --user=root --password=password --database=mydb -e 'select * from team'"
```

Adding an element to the table

```bash
docker exec mysql mysql --user=root --password=password --database=mydb -e "
INSERT INTO team (   \
  id,   \
  name, \
  email,   \
  last_modified \
) VALUES (  \
  2,    \
  'another',  \
  'another@apache.org',   \
  NOW() \
); "
```


Creating Debezium MySQL source connector

```bash
playground connector create-or-update --connector debezium-mysql-source << EOF
{
              "connector.class": "io.debezium.connector.mysql.MySqlConnector",
              "tasks.max": "1",
              "database.hostname": "mysql",
              "database.port": "3306",
              "database.user": "debezium",
              "database.password": "dbz",
              "database.server.id": "223344",

              "database.names" : "mydb",
              "_comment": "old version before 2.x",
              "database.server.name": "server1",
              "database.history.kafka.bootstrap.servers": "broker:9092",
              "database.history.kafka.topic": "schema-changes.mydb",
              "_comment": "new version since 2.x",
              "topic.prefix": "server1",
              "schema.history.internal.kafka.bootstrap.servers": "broker:9092",
              "schema.history.internal.kafka.topic": "schema-changes.mydb",

              "transforms": "RemoveDots",
              "transforms.RemoveDots.type": "org.apache.kafka.connect.transforms.RegexRouter",
              "transforms.RemoveDots.regex": "(.*)\\\\.(.*)\\\\.(.*)",
              "transforms.RemoveDots.replacement": "\$1_\$2_\$3"
          }
EOF
```


Verifying topic `dbserver1_mydb_team`

```bash
playground topic consume --topic dbserver1_mydb_team --min-expected-messages 2 --timeout 60
```

Result:

```json
{
    "before": null,
    "after": {
        "dbserver1_mydb_team.Value": {
            "id": 1,
            "name": "kafka",
            "email": "kafka@apache.org",
            "last_modified": 1570207570000
        }
    },
    "source": {
        "version": {
            "string": "0.9.5.Final"
        },
        "connector": {
            "string": "mysql"
        },
        "name": "dbserver1",
        "server_id": 0,
        "ts_sec": 0,
        "gtid": null,
        "file": "mysql-bin.000003",
        "pos": 457,
        "row": 0,
        "snapshot": {
            "boolean": true
        },
        "thread": null,
        "db": {
            "string": "mydb"
        },
        "table": {
            "string": "team"
        },
        "query": null
    },
    "op": "c",
    "ts_ms": {
        "long": 1570207619721
    }
}
```
N.B: Control Center is reachable at [http://127.0.0.1:9021](http://127.0.0.1:9021])
