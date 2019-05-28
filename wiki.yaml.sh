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
EOF
    exit 1
  }
  source $THIS_DIR/.env
  [ -n "${FQDN:-}" ]    || { echo ".env missing FQDN" ; FATAL=1; }
  export FQDN

  [ -z "${FATAL:-}" ] || exit 1
}


random-string() {
  node -e 'console.log(require("crypto").randomBytes(64).toString("hex"))'
}

emit-yaml() {
  local SECRET="$(random-string)"
  local RANDOM="$(random-string)"
cat <<EOF
main
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: wiki-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wiki
  template:
    metadata:
      labels:
        app: wiki
    spec:
      initContainers:
      - name: wiki-config
        image: wiki
        volumeMounts:
          - name: dot-wiki
            mountPath: /home/app/.wiki
        env:
        - name: DOMAIN
          value: ${FQDN}
        command: |+
          cat <<OWNER > /home/app/.wiki/${FQDN}.owner.json
          {
            "name": "The Owner",
            "friend": {
              "secret": "${SECRET}"
            }
          }
          OWNER
          cat <<CONFIG > /home/app/.wiki/config.json
          {
            "admin": "${SECRET}",
            "farm: true,
            "cookieSecret": "${RANDOM}",
            "secure_cookie": "secure",
            "security_type": "friends",
            "wikiDomains": {
              "${FQDN}" : {
                "id": "/home/app/.wiki/${FQDN}.owner.json"
              }
            }
          }
          CONFIG
      containers:
      - name: farm
        image: wiki
        ports:
        - containerPort: 3000
        volumeMounts:
          - name: dot-wiki
            mountPath: /home/app/.wiki
      volumes:
      - name: dot-wiki
        hostPath:
          path: ${HOME}/.wiki-k8s
---
apiVersion: v1
kind: Service
metadata:
  name: wiki-service
spec:
  ports:
  - name: http
    targetPort: 3000
    port: 80
  - name: https
    targetPort: 3000
    port: 443
  selector:
    app: wiki
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: wiki-ingress
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.frontend.entrypoints: http,https
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: wiki-service
          servicePort: http
EOF
}

main
