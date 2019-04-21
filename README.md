# Wiki and Kubernetes

We began this experiment with help from this tutorial explaining how
to run traefik with kubernetes with docker for mac.

https://medium.com/@geraldcroes/kubernetes-traefik-101-when-simplicity-matters-957eeede2cf8

# TL;DR

    brew install kubernetes-helm
    helm init   # TODO: learn about --tiller-tls-verify
    helm install stable/traefik \
      --name traefik \
      --namespace kube-system \
      --set dashboard.enabled=true,dashboard.domain=ingres.localtest.me
    open http://ingres.localtest.me

    kubectl apply -f wiki.yml
    open http://wiki.localtest.me

# Other notes

This is almost working. (Lacks TLS & wiki configs & admin...)

I had to manually enable kubernetes via the preferences in Docker for Mac.
There's a kubernetes tab in the preferences window and in there a checkbox
to enable it. I am also checking "Show system containers (advanced)" for
my own troubleshooting.

In the Reset tab there is a button to reset the Kubernetes cluster. I have
used this a couple times while testing and re-testing these instructions.
As I get further along and begin to collect data I care about, I'll have to
get more careful about the use of that reset button.


TODO:
- [ ] figure out how to get TLS with self-signed certs
- [ ] figure out how to get wiki configured to define an owner & admin
- [ ] figure out how to upgrade wiki
- [ ] test installing wiki plugins
- [ ] figure out development workflow
- [ ] test same installation with Digital Ocean k8s & real DNS names
