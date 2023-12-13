# Kubeflow demo

Development-only Kubernetes Bicep Example for running Kubeflow.
Please note: This repository and its contents are currently a work in progress. Features, documentation, and the overall project structure may be incomplete and subject to change. 


## Table of Contents
- [TLDR](#tldr)
- [Introduction](#introduction)
- [Bicep](#bicep)
- [Terraform](#terraform)
- [Kubeflow](#kubeflow)
- [Disclaimer](#disclaimer)

## TLDR

To deploy a cluster with Bicep, you will need to edit just a few variables in the [deployment](platform/bicep/script/deployment.sh)
 script. Fork the repo or just clone this one.

```sh
git clone https://github.com/jacqinthebox/kubeflow-demo.git && cd kubeflow-demo/platform/bicep/script
chmod +x deployment.sh

# edit deployment.sh to edit variables
# then run one by one
./deployment.sh init

./deployment.sh plan

./deployment.sh apply
```

## Introduction

Adjustments:

* Hack for Istio
* Check gitignore for excluding env or ENV
* Add namespace to eliminate error `ConfigMap/default-install-config-9h2h2b6hbk namespace not specified: the server could not find the requested resource`
* Turn on autoscaling

## Bicep

## Terraform

## Kubeflow

## Disclaimer
This Bicep example is designed solely for development purposes. It offers a quick and convenient way to spin up an AKS cluster for development and testing environments. However, please be aware that this example does not include configurations and practices essential for an enterprise-grade AKS deployment.

For those seeking a more production-ready solution, the Terraform example is better aligned with production standards. 
