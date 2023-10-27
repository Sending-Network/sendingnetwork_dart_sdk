#!/usr/bin/env bash
docker run -d --name synapse --tmpfs /data \
    --volume="$(pwd)/test_driver/synapse/data/node.yaml":/data/node.yaml:rw \
    --volume="$(pwd)/test_driver/synapse/data/localhost.log.config":/data/localhost.log.config:rw \
    -p 80:80 sdndotorg/synapse:latest
