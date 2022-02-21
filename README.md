# aca-to-k8s

[Azure Container Apps](https://azure.microsoft.com/en-gb/services/container-apps/) is a really easy way to deploy containerised applications, with serverless autoscaling and microservices features baked in, but without having to deal with the complexities of Kubernetes.

**But** how can you be sure that if you adopt it now then you won't get locked in? You don't want to get stuck further down the line if your project starts to hit the limits of ACA's capabilities.

This utility takes advantage of the fact that ACA is built on AKS with open source extensions to let you "eject" from Azure Container Apps to a full AKS cluster should it become necessary, so you can use ACA with confidence.

(Until it runs end-to-end and there's a first release, what action there is will be happening on the dev branch.)