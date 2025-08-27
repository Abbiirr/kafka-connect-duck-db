#!/usr/bin/env bash
# Deletes each connector defined by JSON filenames in spooldir-configs
for cfg in spooldir-configs/*.json; do
  name=$(basename "$cfg" .json)
  echo "Deleting connector: $name"
  curl -s -X DELETE "http://localhost:8083/connectors/$name"
done
