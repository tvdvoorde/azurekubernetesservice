# training

## kubeadm

```bash
az group create -n kubeadm -l westeurope
az vm create -n vm -g kubeadm --image Ubuntu2204 --custom-data "./install.sh" --admin-username azureuser --admin-password Kub3rn3t35@@@ --authentication-type password --size Standard_DS4_v2
```

## aks
