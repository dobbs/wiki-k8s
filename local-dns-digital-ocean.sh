#!/bin/bash -eu
set -o pipefail
IFS=$'\t\n\r'

readonly THIS_DIR=$( cd $(dirname $0); pwd )

usage() {
  cat <<EOF
Usage: $(basename $0) [CMD]
CMD can be one of:
  list-cnames             list configured CNAME records in ${FQDN}

  create-fqdn             create ${FQDN} if it does not already exist
  create-wildcard-cname   create *.${FQDN} if it does not already exist
  main                    both of the above
EOF
}

main() {
  create-fqdn 127.0.0.1
  create-wildcard-cname
}

create-environment() {
  [ -f "$THIS_DIR/.env" ] || {
    cat <<EOF
Please create .env file with the following variables:
FQDN
TOKEN_FILE
EOF
    exit 1
  }
  source $THIS_DIR/.env
  [ -n "${FQDN:-}" ]    || { echo ".env missing FQDN" ; FATAL=1; }
  [ -n "${TOKEN_FILE:-}" ] || { echo ".env missing TOKEN_FILE" ; FATAL=1; }

  [ -z "${FATAL:-}" ] || exit 1
}

create-fqdn() {
  local IP="${1:-MISSING}"
  [ "$IP" == "MISSING" ] && {
    echo "create-fqdn must provide IP address"
    exit 1
  }
  fqdn-exists || {
    do-api -X POST \
           -d "{\"name\":\"${FQDN}\",\"ip_address\":\"${IP}\"}" \
           "https://api.digitalocean.com/v2/domains"
  }
}

create-wildcard-cname() {
  wildcard-cname-exists || {
    do-api -X POST \
           -d "{\"type\":\"CNAME\",\"name\":\"*\",\"data\":\"@\",\"priority\":null,\"port\":null,\"weight\":null}" \
           "https://api.digitalocean.com/v2/domains/${FQDN}/records"
  }
}

fqdn-exists() {
  # not_found is in the error payload if the domain doesn't exist
  # so this code is a double-negative: true if we don't find "not_found"
  do-api -sS -X GET "https://api.digitalocean.com/v2/domains/${FQDN}" \
    | grep -qv not_found
}

wildcard-cname-exists() {
  list-cnames \
    | grep -q '^*'
}

list-cnames() {
  do-api -sS -X GET \
         "https://api.digitalocean.com/v2/domains/${FQDN}/records" \
    | jq -r '.domain_records[] | select(.type == "CNAME") | .name, .data' \
    | paste - -
}

create-cname() {
  local SUBDOMAIN="${1:-*}"
  cname-exists $SUBDOMAIN || {
    local URL="https://api.digitalocean.com/v2/domains/${FQDN}/records"
    do-api -X POST -d@- $URL <<EOF
{
  "type" : "CNAME",
  "name" : "$SUBDOMAIN",
  "data" : "@",
  "priority" : null,
  "port" : null,
  "weight" : null
}
EOF
  }
}

cname-exists() {
  local SUBDOMAIN="${1:-UNSPECIFIED}"
  list-cnames | grep -q "^$SUBDOMAIN"
}

do-api() {
  curl \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $(token)" \
    $@
}

token() {
  cat $TOKEN_FILE
}

case ${1:-} in
  list-cnames \
    | create-cname \
    | create-fqdn \
    | create-wildcard-cname \
    | wildcard-cname-exists \
    | main \
    )
      readonly CMD=${1}
      shift
      ;;
  *)
    readonly CMD=usage
    ;;
esac

create-environment
$CMD $@
