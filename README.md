# Wiki and Kubernetes

# TL;DR

Create a .env file similar to the following (substitute your own values)

    FQDN=example.com
    TOKEN_FILE=~/.digitalocean-token
    ACME_EMAIL=someone@example.com

Run script to create DNS records in digital ocean

    ./local-dns-digital-ocean.sh

Run script to merge env vars into .yaml files

    ./merge-dot-env.sh

Then install helm

    brew install kubernetes-helm
    helm init   # TODO: learn about --tiller-tls-verify

Use helm to install traefik with our custom config

    helm install stable/traefik --name traefik \
      --namespace kube-system --values traefik-values.yaml

Apply the configured wiki.yaml to your kubernetes cluster

    kubectl apply -f wiki.yaml
    open http://local.dbbs.co

Get the admin password on your clipboard

    kubectl exec -ti \
      $(kubectl get pods -l app=wiki -o jsonpath='{.items[0].metadata.name}') \
      -- jq -r .admin .wiki/config.json \
      | pbcopy

# Wiki Development

We mount a local folder ~/workspace/fedwiki inside the wiki farm
container. This is a convenient place to create experimental wiki
plugins or to experiment with changes to wiki-client or wiki-server.

# Notes

These things may be useful to other authors.

I had to manually enable kubernetes via the preferences in Docker for Mac.
There's a kubernetes tab in the preferences window and in there a checkbox
to enable it. I am also checking "Show system containers (advanced)" for
my own troubleshooting.

I have repeatedly reset my local kubernetes cluster so that I could
confirm these instructions work from scratch. If you get stuck
deviating from these instructions, and if you don't have other things
running in your own kubernetes, this might come in handy. In the Reset
tab there is a button to reset the Kubernetes cluster. The whole point
of this button is to loose data on purpose. Use that power carefully.
:-)

# Troubleshooting TLS certs

After a complete re-install of docker & kubernetes & wiki-k8s, we
encountered some problems getting valid certificates working. The
default behavior is to provide self-signed certs when the real
certificate creation fails. However, that defeats the point of using
real certs.

Stop and restart proxy server (traefik)

    # set replicas to 0
    kubectl scale deployment traefik --namespace=kube-system --replicas=0

    # watch status to confirm traefik has stopped
    #  traefik will be missing among the pods & the replica set will show all 0s
    kubectl get all --namespace=kube-system

    # set replicas to 1
    kubectl scale deployment traefik --namespace=kube-system --replicas=1

    # apply patience... it takes a little while (more than a second less than a
    # minute?) for things to resume

Example logs for traefik showing acme challenge failures:

    kubectl logs -f -l app=traefik --namespace=kube-system

    {"level":"info","msg":"legolog: [WARN] [local.dbbs.co] acme: error cleaning up: digitalocean: unknown record ID for '_acme-challenge.local.dbbs.co.' ","time":"2019-08-31T13:48:45Z"}
    {"level":"error","msg":"Error obtaining certificate: acme: Error -\u003e One or more domains had a problem:\n[*.local.dbbs.co] time limit exceeded: last error: NS ns1.digitalocean.com. did not return the expected TXT record [fqdn: _acme-challenge.local.dbbs.co., value: RS3c9MaNPv0Jl798fgsJSF3WJrfkqK7Ne3DHo-YLqgA]: \n[local.dbbs.co] time limit exceeded: last error: NS ns1.digitalocean.com. did not return the expected TXT record [fqdn: _acme-challenge.local.dbbs.co., value: h9twBW6YRijGlcM8ibzqJu69ZnKPKVnp2sHcqTQbZ4w]: \n","time":"2019-08-31T13:48:45Z"}
    {"level":"error","msg":"Unable to obtain ACME certificate for domains \"*.local.dbbs.co,local.dbbs.co\" : unable to generate a certificate for the domains [*.local.dbbs.co local.dbbs.co]: acme: Error -\u003e One or more domains had a problem:\n[*.local.dbbs.co] time limit exceeded: last error: NS ns1.digitalocean.com. did not return the expected TXT record [fqdn: _acme-challenge.local.dbbs.co., value: RS3c9MaNPv0Jl798fgsJSF3WJrfkqK7Ne3DHo-YLqgA]: \n[local.dbbs.co] time limit exceeded: last error: NS ns1.digitalocean.com. did not return the expected TXT record [fqdn: _acme-challenge.local.dbbs.co., value: h9twBW6YRijGlcM8ibzqJu69ZnKPKVnp2sHcqTQbZ4w]: \n","time":"2019-08-31T13:48:45Z"}

# Lessons collected while creating this configuration

These things are likely of interest only to me, but left here more
publicly in case they can serve others trying to discover their own
path into kubernetes deployments.

We began this experiment with help from this tutorial explaining how
to run traefik with kubernetes with docker for mac.

https://medium.com/@geraldcroes/kubernetes-traefik-101-when-simplicity-matters-957eeede2cf8

Helpful guidance for using Helm to automate cert creation:
https://medium.com/nuvo-group-tech/move-your-certs-to-helm-4f5f61338aca
Turns out go community have a Sprig template library with some super
helpful crypto abstractions for use in go templates. Helm can use
those directly.

I also discovered I had a previously installed and now outdated helm
chart for traefik. I took a particularly aggressive approach:

    rm -rf ~/.helm
    # reset kubernetes cluster completely
    helm init

# x509 wildcard certs

- [ ] find the links I was hanging onto about configuring x509 wildcard certs

# TODO:
- [X] figure out how to get TLS with lets encrypt wildcard certs
- [ ] figure out how to upgrade wiki
- [X] figure out development workflow
- [ ] test same installation with Digital Ocean k8s & real DNS names
- [X] figure out how to get TLS with self-signed certs locally
- [X] figure out how to get wiki configured to define an owner & admin
- [X] test installing wiki plugins

# Speculative Goals

    # the install instructions I think I want:
    brew install kubernetes-helm
    ./bin/create-helm-certs
    helm init --tiller-tls-verify ... # reference created certs
    helm install stable/traefik --name traefik \
      --namespace kube-system --values traefik-values.yaml
    helm install -f wiki-wiki.yaml ./wiki-chart

    # TODO: figure out all the settings & put them in wiki-traefik.yaml
    # namespace, domain, dashboard enabled(?), TLS details

# Collected links

- How to create a Helm Chart (e.g. to create a chart for wiki)
  https://daemonza.github.io/2017/02/20/using-helm-to-deploy-to-kubernetes/
