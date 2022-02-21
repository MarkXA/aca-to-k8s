Param(
    [string] $ResourceGroupName,
    [string] $Location,
    [string] $VnetName,
    [string] $AksName,
    [string] $AksSubnetName,
    [string] $VirtualNodesSubnetName
)

# Useful function for parsing JSON results
function ConvertTo-Object {
    ConvertFrom-Json ([String]::Join(" ", $args[0]))
}

"# Delete and recreate the resource group"

az group delete --name $ResourceGroupName --yes
az group create --name $ResourceGroupName --location $Location

"# Create a virtual network and subnet for AKS"

$json = az network vnet create `
    --name $VnetName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --address-prefixes 10.0.0.0/8 `
    --subnet-name $AksSubnetName `
    --subnet-prefix 10.240.0.0/16

$vnet = (ConvertTo-Object $json).newVNet

$json = az network vnet subnet show `
    --resource-group $ResourceGroupName `
    --vnet-name $VnetName `
    --name $AksSubnetName

$aksSubnet = ConvertTo-Object $json

"# Create a subnet for AKS virtual nodes"

az network vnet subnet create `
    --name $VirtualNodesSubnetName `
    --vnet-name $VnetName `
    --resource-group $ResourceGroupName `
    --address-prefixes 10.241.0.0/16

"# Create a service principal"

$json = az ad sp create-for-rbac --role Contributor --scopes $vnet.id

$sp = ConvertTo-Object $json

"# Create the AKS cluster"

az aks create `
    --resource-group $ResourceGroupName `
    --name $AksName `
    --location $Location `
    --node-count 10 `
    --network-plugin azure `
    --service-cidr 10.0.0.0/16 `
    --dns-service-ip 10.0.0.10 `
    --docker-bridge-address 172.17.0.1/16 `
    --vnet-subnet-id $aksSubnet.id `
    --generate-ssh-keys `
    --service-principal $sp.appId `
    --client-secret $sp.password

"# Connect the Kubernetes CLI to the AKS cluster"

az aks get-credentials --resource-group $ResourceGroupName --name $AksName --overwrite-existing

"# Enable virtual nodes"

az aks enable-addons `
    --resource-group $ResourceGroupName `
    --name $AksName `
    --addons virtual-node `
    --subnet-name $VirtualNodesSubnetName

"# Install KEDA, Dapr and OSM"

helm repo add kedacore https://kedacore.github.io/charts
helm repo add dapr https://dapr.github.io/helm-charts/
helm repo add osm https://openservicemesh.github.io/osm
helm repo update

helm upgrade --install keda kedacore/keda `
    --namespace keda `
    --create-namespace `
    --wait

helm upgrade --install dapr dapr/dapr `
    --namespace dapr-system `
    --create-namespace `
    --wait

helm upgrade --install osm osm/osm `
    --namespace kube-system `
    --wait

# TODO: Apply the container apps YAML
