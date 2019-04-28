# Wiki and Kubernetes

We began this experiment with help from this tutorial explaining how
to run traefik with kubernetes with docker for mac.

https://medium.com/@geraldcroes/kubernetes-traefik-101-when-simplicity-matters-957eeede2cf8

Helpful guidance for using Helm to automate cert creation:
https://medium.com/nuvo-group-tech/move-your-certs-to-helm-4f5f61338aca
Turns out go community have a Sprig template library with some super
helpful crypto abstractions for use in go templates. Helm can use
those directly.

# TL;DR

    brew install kubernetes-helm
    helm init   # TODO: learn about --tiller-tls-verify
    helm install stable/traefik \
      --name traefik \
      --namespace kube-system \
      --values traefik-values.yaml
    open http://ingres.localtest.me

    kubectl apply -f wiki.yml
    open http://wiki.localtest.me

# Other notes

This is almost working. (Lacks wiki configs & admin...)

I had to manually enable kubernetes via the preferences in Docker for Mac.
There's a kubernetes tab in the preferences window and in there a checkbox
to enable it. I am also checking "Show system containers (advanced)" for
my own troubleshooting.

In the Reset tab there is a button to reset the Kubernetes cluster. I have
used this a couple times while testing and re-testing these instructions.
As I get further along and begin to collect data I care about, I'll have to
get more careful about the use of that reset button.

I also discovered I had a previously installed and now outdated helm
chart for traefik. I took a particularly aggressive approach:

    rm -rf ~/.helm
    # reset kubernetes cluster completely
    helm init

# x509 wildcard certs

- [ ] find the links I was hanging onto about configuring x509 wildcard certs

# TODO:
- [x] figure out how to get TLS with self-signed certs locally
- [ ] figure out how to get TLS with lets encrypt wildcard certs
- [ ] figure out how to get wiki configured to define an owner & admin
- [ ] figure out how to upgrade wiki
- [ ] test installing wiki plugins
- [ ] figure out development workflow
- [ ] test same installation with Digital Ocean k8s & real DNS names

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
