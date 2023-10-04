Upgrade system
```
apt update && apt -y full-upgrade
```
Install k3s
```
curl -sfL https://get.k3s.io | bash -s - --write-kubeconfig-mode 644
```
Expected installation output – The process should complete in few seconds / minutes.
[INFO]  Finding release for channel stable
[INFO]  Using v1.27.4+k3s1 as release
[INFO]  Downloading hash https://github.com/k3s-io/k3s/releases/download/v1.27.4+k3s1/sha256sum-amd64.txt
[INFO]  Downloading binary https://github.com/k3s-io/k3s/releases/download/v1.27.4+k3s1/k3s
[INFO]  Verifying binary download
[INFO]  Installing k3s to /usr/local/bin/k3s
[INFO]  Skipping installation of SELinux RPM
[INFO]  Creating /usr/local/bin/kubectl symlink to k3s
[INFO]  Creating /usr/local/bin/crictl symlink to k3s
[INFO]  Creating /usr/local/bin/ctr symlink to k3s
[INFO]  Creating killall script /usr/local/bin/k3s-killall.sh
[INFO]  Creating uninstall script /usr/local/bin/k3s-uninstall.sh
[INFO]  env: Creating environment file /etc/systemd/system/k3s.service.env
[INFO]  systemd: Creating service file /etc/systemd/system/k3s.service
[INFO]  systemd: Enabling k3s unit
Created symlink /etc/systemd/system/multi-user.target.wants/k3s.service → /etc/systemd/system/k3s.service.
[INFO]  systemd: Starting k3s

Get nodes
```
$ kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
debian   Ready    control-plane,master   33s   v1.27.4+k3s1
```
Install kustomize
```
apt install git vim build-essential apparmor apparmor-utils -y

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize /usr/local/bin
kustomize version
```

Install AWX Operator
```
apt update
apt install curl jq -y
RELEASE_TAG=`curl -s https://api.github.com/repos/ansible/awx-operator/releases/latest | grep tag_name | cut -d '"' -f 4`
echo $RELEASE_TAG

```
Create yaml
```
tee kustomization.yaml<<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=$RELEASE_TAG

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator

# Specify a custom namespace in which to install AWX
namespace: awx
EOF
```
apply yaml
```
kustomize build . | kubectl apply -f -
```

Install kubectx and Switch namespace
```
apt-get install kubectx
kubens awx 
```
Check pods
```
kubectl get pods -n awx
```

Create PVC
```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-data-pvc
  namespace: awx
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: local-path
  resources:
    requests:
      storage: 8Gi
EOF
```
Create AWX deployment yaml
```
tee awx-deploy.yml<<EOF
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  service_type: nodeport
  projects_persistence: true
  projects_storage_access_mode: ReadWriteOnce
  web_extra_volume_mounts: |
    - name: static-data
      mountPath: /var/lib/projects
  extra_volumes: |
    - name: static-data
      persistentVolumeClaim:
        claimName: static-data-pvc
EOF
```
Update the Kustomize file:
```
tee kustomization.yaml<<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=$RELEASE_TAG
  # Add this extra line:
  - awx-deploy.yml
# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator

# Specify a custom namespace in which to install AWX
namespace: awx
EOF
```

Apply configuration
```
kustomize build . | kubectl apply -f -
```
Wait some minutes and check deployment

```
kubectl  get pods -l "app.kubernetes.io/managed-by=awx-operator"
```

If you want check logs ...

```
kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager
```


You can edit the Node Port and set to figure of your preference
```
$ kubectl edit svc awx-service
....
ports:
  - name: http
    nodePort: XXX
    port: 80
    protocol: TCP
    targetPort: 8052
```



Optional: Install metallb and assign ip address to AWX web service

```
MetalLB_RTAG=$(curl -s https://api.github.com/repos/metallb/metallb/releases/latest|grep tag_name|cut -d '"' -f 4|sed 's/v//')

mkdir ~/metallb
cd ~/metallb

wget https://raw.githubusercontent.com/metallb/metallb/v$MetalLB_RTAG/config/manifests/metallb-native.yaml

kubectl apply -f metallb-native.yaml

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

kubectl apply -f ipaddress_pools.yaml
```

X.X.X.X-X.X.X.X = choice a range of ip adress to assign, example 192.168.1.30-192.168.1.40


Edit awx service and assign an IP address from Pool
```
# kubectl edit service awx-service
# trovare tye e modificare in :
#  type: LoadBalancer
#  loadBalancerIP: X.X.X.X

```
Edit awk-deploy.yaml with service LoadBalancer

```
 ---
 apiVersion: awx.ansible.com/v1beta1
 kind: AWX
 metadata:
   name: awx
 spec:
   service_type: LoadBalancer
   projects_persistence: true
   projects_storage_access_mode: ReadWriteOnce
   web_extra_volume_mounts: |
     - name: static-data
       mountPath: /var/lib/projects
   extra_volumes: |
     - name: static-data
       persistentVolumeClaim:
         claimName: static-data-pvc
```
Apply it
```
kubectl apply -f awk-deploy.yaml
```

Get current admin password
```
kubectl get secret --namespace awx awx-admin-password -o jsonpath="{.data.password}" | base64 -d; echo
```

