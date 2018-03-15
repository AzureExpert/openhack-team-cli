    CLIENT_ID=$(az aks show --resource-group myResourceGroup --name myAKSCluster --query "servicePrincipalProfile.clientId" --output tsv)
    ACR_ID=$(az acr show --name <acrName> --resource-group myResourceGroup --query "id" --output tsv)
    az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID
    