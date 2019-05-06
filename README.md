# Wiki and Kubernetes

# TL;DR

    brew install kubernetes-helm
    helm init   # TODO: learn about --tiller-tls-verify
    helm install stable/traefik --name traefik \
      --namespace kube-system --values traefik-values.yaml

Modify wiki.yaml to configure for your local environment

    perl -pi -e 's{^(\s+path: )HOME(/.*)$}{$1$ENV{"HOME"}$2}' wiki.yaml

Apply the configured wiki.yaml to your kubernetes cluster

    kubectl apply -f wiki.yaml
    open http://wiki.localtest.me

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
- [ ] figure out how to get TLS with lets encrypt wildcard certs
- [ ] figure out how to upgrade wiki
- [ ] figure out development workflow
- [ ] test same installation with Digital Ocean k8s & real DNS names
- [X] figure out how to get TLS with self-signed certs locally
- [X] figure out how to get wiki configured to define an owner & admin
- [X] test installing wiki plugins

# Goals

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
