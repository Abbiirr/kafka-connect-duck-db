#!/usr/bin/env bash
# Prints the current state (e.g., RUNNING, FAILED) for each connector
for cfg in spooldir-configs/*.json; do
  name=$(basename "$cfg" .json)
  echo -n "$name: "
  curl -s "http://localhost:8083/connectors/$name/status" | jq
done
