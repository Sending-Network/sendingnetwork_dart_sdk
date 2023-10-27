#!/usr/bin/env bash
chown -R 991:991 test_driver/radix

# creating integration test SSL certificates
docker run --rm --entrypoint="" \
  --volume="$(pwd)/test_driver/radix/data":/mnt:rw \
  sdndotorg/radix-monolith:latest \
  /usr/bin/generate-keys \
  -private-key /mnt/sdn_key.pem \
  -tls-cert /mnt/server.crt \
  -tls-key /mnt/server.key

docker run -d --volume="$(pwd)/test_driver/radix/data":/etc/radix:rw \
  --name radix -p 80:8008 sdndotorg/radix-monolith:latest -really-enable-open-registration
