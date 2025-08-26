# one-time setup
mc alias set local http://localhost:9000 minioadmin minioadmin123
mc mb local/banking-lake
mc ls local

# 1) Connector status
curl -s http://localhost:8083/connectors/minio-sink-banking/status | jq

# 2) Effective config (confirm bucket name, endpoint, topics.regex)
curl -s http://localhost:8083/connectors/minio-sink-banking | jq '.config'

# 3) Do topics actually match your regex?
# You should see db.public.* (because RegexRouter renamed them)
curl -s http://localhost:8083/connectors/banking-debezium-postgres | jq '.config.transforms.route.*'
# Or list topics via your broker tooling / kcat

# 4) After a few minutes, list objects:
mc ls -r local/banking-lake


curl -s -X PUT http://localhost:8083/connectors/minio-sink-banking/config \
  -H 'Content-Type: application/json' \
  -d @minio-sink.json

curl -s http://localhost:8083/connectors/minio-sink-banking/status | jq
