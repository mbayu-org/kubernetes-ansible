#!/bin/bash

#proxmox start control-plane and worker VMs
sudo qm list | grep 17
#control-plane
sudo qm start 171

# workers
sudo qm start 173
sudo qm start 174
sudo qm start 175

sudo qm list | grep 17 

# install ansible
sudo apt update
sudo apt-get install python3 python3-pip -y
sudo pip3 install ansible
ansible --version

#helm 3.
sudo curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
sudo ./get_helm.sh

export ANSIBLE_NOCOWS=1
ansible-playbook playbooks/cleanup_cni_node.yml
ansible-playbook setup_master_node.yml
ansible-playbook setup_worker_nodes.yml

ssh 10.1.1.171 sudo cat /root/.kube/config | sudo tee -a /home/mobile/.kube/config

kubectl get nodes -o wide


# metallb 
helm install metallb bitnami/metallb --namespace kube-system --set configInline.address-pools[0].name=default --set configInline.address-pools[0].protocol=layer2 --set configInline.address-pools[0].addresses[0]=10.1.1.180-10.1.1.189

# nfs storageClass, PVC und pv
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set storageClass.defaultClass=true \
    --set replicaCount=3	\
    --set nfs.server=10.1.1.5 \
    --set nfs.path=/nfsshare/k8s

cat <<EOF | kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
EOF

cat <<EOF | kubectl apply -f -
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
spec:
  containers:
  - name: test-pod
    image: gcr.io/google_containers/busybox:1.24
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "touch /mnt/SUCCESSMMMMM && exit 0 || exit 1"
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: test-claim
EOF

kubectl get all --all-namespaces -o wide

exit 0


# elk ELK
kubectl apply -f https://download.elastic.co/downloads/eck/1.4.1/all-in-one.yaml

cat <<EOF | kubectl apply -f -
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: quickstart
spec:
  version: 7.11.2
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
EOF

exit 0
export verb=apply;
export verb=delete;

export URLPREFIX=https://raw.githubusercontent.com/arangodb/kube-arangodb/1.1.5/manifests;

kubectl $verb -f $URLPREFIX/arango-crd.yaml;
kubectl $verb -f $URLPREFIX/arango-deployment.yaml;
kubectl $verb -f $URLPREFIX/arango-storage.yaml;
kubectl $verb -f $URLPREFIX/arango-deployment-replication.yaml;

kubectl $verb -f https://raw.githubusercontent.com/arangodb/kube-arangodb/master/examples/single-server.yaml
kubectl $verb -f https://raw.githubusercontent.com/arangodb/kube-arangodb/master/examples/simple-cluster.yaml



kubectl $verb -f https://raw.githubusercontent.com/arangodb/kube-arangodb/1.1.5/manifests/arango-crd.yaml

kubectl $verb -f https://raw.githubusercontent.com/arangodb/kube-arangodb/1.1.5/manifests/arango-deployment.yaml

kubectl $verb -f https://raw.githubusercontent.com/arangodb/kube-arangodb/1.1.5/manifests/arango-storage.yaml

kubectl $verb -f https://raw.githubusercontent.com/arangodb/kube-arangodb/1.1.5/manifests/arango-deployment-replication.yaml

kubectl get all | grep arango;




