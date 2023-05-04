#!/bin/bash -v
swapoff -a
cat <<EOF >/etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

mkdir /etc/apt/keyrings
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt update -y
apt install -y apt-transport-https ca-certificates curl jq containerd kubeadm=1.26.4-00 kubelet=1.26.4-00 kubectl=1.26.4-00

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl restart containerd
apt-mark hold kubeadm kubelet kubectl
IP=$(curl ifconfig.io)
kubeadm init --kubernetes-version 1.26.4 --apiserver-cert-extra-sans $IP --apiserver-bind-port 443
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml
mkdir /home/azureuser/.kube
cp -i /etc/kubernetes/admin.conf /home/azureuser/.kube/config
chown azureuser /home/azureuser/.kube/config
kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-
cat <<EOF | tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
