# Kubernetes Master Node Initialization (kubeadm init) Guide

## 1. Prerequisites
- Run on the master node as root or with sudo privileges
- Ensure firewall, SELinux, and swap are disabled as required
- kubelet, kubeadm, and kubectl must be installed and version-checked


## 2. Check pod-network-cidr for your network plugin
- Example: Calico → 192.168.156.0/24 (your test environment), Flannel → 10.244.0.0/16


## 3. Run kubeadm init (on the master node)
**On the master node (192.168.156.30):**
```bash
kubeadm init \
  --apiserver-advertise-address=192.168.156.30 \
  --pod-network-cidr=192.168.156.0/24
```
Where:
- 192.168.156.30 is your master node IP (see inventory.ini)
- 192.168.156.0/24 is your pod network CIDR (test environment)

## 4. Set up kubeconfig for kubectl (on the master node)
**On the master node (192.168.156.30):**
```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

## 5. Install a network plugin (e.g., Calico) (on the master node)
**On the master node (192.168.156.30):**
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```


## 6. Get the worker node join command (on each worker node)

### Option 1: Use the join command output from kubeadm init (step 3)
After running `kubeadm init`, the output will include a `kubeadm join ...` command with the required token and hash values. Copy and use this command as shown.

### Option 2: If you missed the output, retrieve the token and hash on the master node
**On the master node (192.168.156.30):**

To get the current join token:
```bash
kubeadm token list
```
If no token exists, create one:
```bash
kubeadm token create
```

To get the discovery-token-ca-cert-hash value:
```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | \
  sed 's/^.* //'
```
Or, use the following command to get the full join command (Kubernetes 1.15+):
```bash
kubeadm token create --print-join-command
```

### On each worker node (as root):
  - 192.168.156.31 (worker1)
  - 192.168.156.32 (worker2)
  - 192.168.156.33 (worker3)
  - 192.168.156.34 (worker4)
```bash
kubeadm join 192.168.156.30:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

## 7. Check cluster status (on the master node)
**On the master node (192.168.156.30):**
```bash
kubectl get nodes
kubectl get pods -A
```

---

> Note: Adjust pod-network-cidr, network plugin, and master IP according to your environment.
