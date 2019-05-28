#!/bin/bash -eu
set -o pipefail
IFS=$'\t\n\r'
readonly THIS_DIR=$( cd $(dirname $0); pwd )

main() {
  enforce-environment-file
  emit-yaml
}

enforce-environment-file() {
  [ -f "$THIS_DIR/.env" ] || {
    cat <<EOF
Please create .env file with the following variables:
FQDN
TOKEN_FILE
ACME_EMAIL
EOF
    exit 1
  }
  source $THIS_DIR/.env
  [ -n "${FQDN:-}" ]    || { echo ".env missing FQDN" ; FATAL=1; }
  [ -n "${TOKEN_FILE:-}" ] || { echo ".env missing TOKEN_FILE" ; FATAL=1; }
  [ -n "${ACME_EMAIL:-}" ] || { echo ".env missing ACME_EMAIL" ; FATAL=1; }

  READ_TOKEN_FILE="$(cat $TOKEN_FILE)"
  export ACME_EMAIL FQDN READ_TOKEN_FILE

  [ -z "${FATAL:-}" ] || exit 1
}

emit-yaml() {
cat <<EOF
ssl:
  enabled: true
acme:
  enabled: true
  staging: true
  logging: true
  challengeType: "dns-01"
  email: "${ACME_EMAIL}"
  dnsProvider:
    name: digitalocean
    digitalocean:
      DO_AUTH_TOKEN: "${READ_TOKEN_FILE}"
  domains:
    enabled: true
    domainsList:
      - main: "*.${FQDN}"
      - sans:
        - "${FQDN}"
EOF
}

main
