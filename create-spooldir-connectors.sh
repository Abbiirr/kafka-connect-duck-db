#!/usr/bin/env bash
# Uses each config file to create or update connectors
for cfg in spooldir-configs/*.json; do
  name=$(basename "$cfg" .json)
  echo "Creating/Updating connector: $name"
  curl -s -X PUT "http://localhost:8083/connectors/$name/config" \
    -H "Content-Type: application/json" \
    --data @"$cfg"
done
