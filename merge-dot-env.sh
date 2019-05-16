#!/bin/bash -eu
set -o pipefail
IFS=$'\t\n\r'

readonly THIS_DIR=$( cd $(dirname $0); pwd )

usage() {
  cat <<EOF
Usage: $(basename $0)
  will apply values from .env over wiki.tmpl and traefik-values.tmpl
EOF
}

main() {
  cat <<'EOF' | perl -pi.orig - wiki.tmpl traefik-values.tmpl
s{^(\s+path: )HOME(/.*)$}{$1$ENV{"HOME"}$2};
s{(FQDN)}{$ENV{$1}}g;
s{(READ_TOKEN_FILE)}{$ENV{$1}}g;
s{(ACME_EMAIL)}{$ENV{$1}}g;
EOF
  mv wiki{.tmpl,.yaml}
  mv traefik-values{.tmpl,.yaml}
  mv wiki.tmpl{.orig,}
  mv traefik-values.tmpl{.orig,}
}

create-environment() {
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

  READ_TOKEN_FILE="$(token)"
  export ACME_EMAIL FQDN READ_TOKEN_FILE

  [ -z "${FATAL:-}" ] || exit 1
}

token() {
  cat $TOKEN_FILE
}

create-environment
main
