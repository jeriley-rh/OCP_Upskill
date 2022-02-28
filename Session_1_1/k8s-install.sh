#!/bin/bash
#-------------------------------------------------------------------------------------
# These are the steps and files used to deploy k8s 1.23 in the video. Please modify
# k8s/calico.yaml and k8s/metallb-deploy.yaml to match your pod-network-cidr
#------------------------------------------------------------------------------------
# Note: crio v1.22 is installed due to a Bug
#------------------------------------------------------------------------------------

OS=Ubuntu_20.04
CRIO_VERSION=1.22

# TEST to ensure that we are executing this script as the root.
	if [ "$(id -u)" != "0" ]; then
		echo "This script must be run as root" 1>&2
		exit 1
	fi


echo "---------------Adding k8s repos and installing crio---------------" 
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -
apt-get update
apt install cri-o cri-o-runc cri-tools -y
systemctl enable --now crio.service

sleep 10

echo "---------------Install Kubelet, Kubeadm, and Kubectl---------------"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl

sleep 3

echo "---------------Disabling Swap for Kubernetes Install---------------"
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

echo "---------------Create the .conf file to load the modules at bootup---------------"
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

echo "---------------Enabling Kernel Modules for overlay and br_netfilter---------------"
modprobe overlay > /dev/null 2>&1
modprobe br_netfilter > /dev/null 2>&1

echo "---------------Updating sysctl settings required for Kubernetes Install---------------"

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo "---------------Reloading sysctl---------------"
sysctl --system > /dev/null 2>&1

echo "---------------Install Kubernetes---------------"
#Default pod network is 192.168.0.0/16 - Change if it conflicts like I did
#kubeadm init --pod-network-cidr=192.168.100.0/16
kubeadm init

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "---------------Creating .kube folder, copy kubeconfig, and add var to .bash_profile---------------"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/conf
tee $HOME/.bash_rc<<EOF
export KUBECONFIG=$HOME/.kube/conf
EOF
source $HOME/.bash_profile

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "---------------Install Container Network Interface (CNI) - Calico---------------"
#Modify Line 4223 of calico.yaml if you used a non-default pod network cidr
#Example: value: "192.168.100.0/16"
kubectl apply -f k8s/calico.yaml

echo "---------------Install MetalLB - Load Balancer for Bare Metal installs---------------"
#Modify line 20 of metallb-deploy.yaml to match the local IP of your server
#Example: 20: 192.168.50.88-192.168.50.88
kubectl apply -f k8s/metallb-deploy.yaml

sleep 30

echo "---------------Remove Master taint from all nodes---------------"
kubectl taint nodes --all node-role.kubernetes.io/master-

sleep 30

echo "---------------Deploy Ingress-nginx---------------"
kubectl apply -f k8s/ingress-nginx-deploy.yaml

sleep 60

echo "---------------Deploy hello-openshift to test---------------"
#You will need DNS setup for this to work
kubectl apply -f k8s/hello-openshift.yaml

sleep 30

echo ""
echo ""
echo "--------------------------------------------------"
echo "---------------Testing Installation---------------"
kubectl get nodes
echo "--------------------------------------------------"
ls -l /etc/cni/net.d/
echo "--------------------------------------------------"
kubectl get pods -A
echo "--------------------------------------------------"

