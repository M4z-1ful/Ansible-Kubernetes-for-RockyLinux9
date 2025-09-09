# Ansible Kubernetes Installation for Rocky Linux 9

This repository contains Ansible playbooks for automated installation and configuration of Kubernetes clusters on Rocky Linux 9.

## Quick Start

### Prerequisites
- Rocky Linux 9 nodes (1 master + multiple workers)
- SSH access with key-based authentication
- Ansible installed on the control machine

### Installation Steps

1. **Configure your inventory**
   ```bash
   # Edit inventory.ini with your node information
   vi inventory.ini
   ```

2. **Create users and SSH setup**
   ```bash
   ansible-playbook -i inventory.ini 01-user-create.yml
   ```

3. **Install Kubernetes components**
   ```bash
   ansible-playbook -i inventory.ini 02-k8s-install.yml
   ```

4. **Initialize cluster and join nodes**
   ```bash
   ansible-playbook -i inventory.ini 03-k8s-init-cluster.yml
   ```

5. **Check cluster status**
   ```bash
   ansible-playbook -i inventory.ini 04-k8s-check-cluster.yml
   ```

## Files Description

- `inventory.ini` - Inventory file with node information and variables
- `01-user-create.yml` - Creates `kube` user and sets up SSH keys
- `02-k8s-install.yml` - Installs containerd, kubelet, kubeadm, kubectl
- `03-k8s-init-cluster.yml` - Initializes master node and joins workers automatically
- `04-k8s-check-cluster.yml` - Validates cluster installation and status

## Configuration

Edit `inventory.ini` to match your environment:

```ini
[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
pod_network_cidr=192.168.156.0/24

[masters]
k8s-master ansible_host=192.168.156.30

[workers]
k8s-worker1 ansible_host=192.168.156.31
k8s-worker2 ansible_host=192.168.156.32
k8s-worker3 ansible_host=192.168.156.33
k8s-worker4 ansible_host=192.168.156.34
```

## Troubleshooting

If `04-k8s-check-cluster.yml` shows connection refused errors, it means:
- The cluster hasn't been initialized yet (run step 4 first)
- The API server isn't running properly
- Firewall issues on port 6443

## Manual Cluster Setup (Alternative)

If you prefer manual setup instead of automated cluster initialization, see the appendix below.

---

## Appendix: Manual Cluster Setup Tips

### Manual kubeadm init (Alternative to step 4)

**On the master node (192.168.156.30):**
```bash
kubeadm init \
  --apiserver-advertise-address=192.168.156.30 \
  --pod-network-cidr=192.168.156.0/24
```

**Set up kubeconfig:**
```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

**Install network plugin (Calico):**
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Manual Worker Node Join

**Get join command on master:**
```bash
kubeadm token create --print-join-command
```

**On each worker node:**
```bash
kubeadm join 192.168.156.30:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

### Token and Hash Recovery

**Get current token:**
```bash
kubeadm token list
```

**Create new token:**
```bash
kubeadm token create
```

**Get discovery hash:**
```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | \
  sed 's/^.* //'
```

### Cluster Status Check

**Check nodes:**
```bash
kubectl get nodes
kubectl get pods -A
```
