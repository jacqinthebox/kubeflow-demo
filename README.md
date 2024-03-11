# Kubeflow demo

Development-only Kubernetes Bicep Example for running Kubeflow.
Please note: This repository and its contents are currently a work in progress. Features, documentation, and the overall project structure may be incomplete and subject to change. 


## Table of Contents
- [Kubeflow demo](#kubeflow-demo)
  - [Table of Contents](#table-of-contents)
  - [TLDR](#tldr)
  - [Introduction](#introduction)
  - [Bicep](#bicep)
  - [Terraform](#terraform)
  - [Kubeflow](#kubeflow)
  - [Disclaimer](#disclaimer)

## TLDR

Use the he Azure Cloud Shell, or install: 

```sh
sudo apt install az-cli kubectl jq wget curl # or use any other package manaager
az aks install-cli # kubelogin
```

To deploy a cluster with Bicep, you will need to edit just a few variables in the [deployment](platform/bicep/script/deployment.sh)
 script. 

1. Fork or clone this repo and make executable. 

```sh
git clone https://github.com/jacqinthebox/kubeflow-demo.git && cd kubeflow-demo/platform/bicep/script
chmod +x deployment.sh
```
2. Edit [deployment.sh](platform/bicep/script/deployment.sh) and change the subscription id, and optionally change the other vars in the Config section.

```sh
vim deployment.sh # or any other editor
```   

4. Run `init` to create the resource group 

```sh
az login set --subscription <your sub>
./deployment.sh init
```
4. Then run `plan` to do a dry-run

```sh
./deployment.sh plan
```

5. Then run `apply` to deploy the cluster including Kubeflow. 

```sh
./deployment.sh apply
```

6. Once the cluster deployment is finished, you can connect to the cluster (click Connect in the Azure portal)

7. To access the dashboard see here: https://www.kubeflow.org/docs/components/central-dash/access/


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
