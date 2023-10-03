# Install guide

Install repository and kubelet kubeadm kubectl
``` bash 
apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

mkdir /etc/apt/keyrings

apt-get install gpg -y

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update

apt-get install -y kubelet kubeadm kubectl && apt-mark hold kubelet kubeadm kubectl
```

Setup Modules
``` bash
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

Swapoff
```
vim /etc/fstab
swapoff -a
```

Containerd
```
apt-get install ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && apt-get install containerd.io -y
mv /etc/containerd/config.toml .
systemctl restart containerd
```

kubeadm init
```
IPADDR=$(hostname -I | awk '{print $1}')
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
kubeadm init --apiserver-advertise-address=$IPADDR  --apiserver-cert-extra-sans=$IPADDR  --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap
kubectl get nodes
export KUBECONFIG=/etc/kubernetes/admin.conf

kubectl get pods --all-namespaces
kubectl cluster-info
kubectl get nodes
```

Calico
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
```
Get pods
```
kubectl get pods --all-namespaces
```

Setting workers node
```
kubectl label node xxx node-role.kubernetes.io/worker=worker
```

Enable metrics
```
kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

kubectl top nodes
```

Enable Metallb
```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
```
Metallb enable address pool
```
tee ipaddress_pools.yaml <<EOF
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production
  namespace: metallb-system
spec:
  addresses:
  - X.X.X.X-X.X.X.X
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advert
  namespace: metallb-system
EOF
```
kubectl apply -f ipaddress_pools.yaml


DASHBOARD
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

cat <<EOF | tee  admin-user.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f admin-user.yaml

cat  <<EOF | tee roles.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f roles.yaml

kubectl -n kubernetes-dashboard create token admin-user
```
