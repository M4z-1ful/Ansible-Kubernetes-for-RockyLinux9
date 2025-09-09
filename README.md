# Ansible Kubernetes Installation for Rocky Linux 9

This repository contains Ansible playbooks for automated installation and configuration of Kubernetes clusters on Rocky Linux 9.

## Features

- **Network Plugin**: Flannel (simple and stable)
- **Fully Automated**: One-click installation script provided
- **State Validation**: Waits until all pods are in Running state
- **Error Handling**: Clear error messages when issues occur during installation

## Quick Start

### Prerequisites
- Rocky Linux 9 nodes (1 master + multiple workers)
- SSH access with key-based authentication
- Ansible installed on the control machine

### Configuration

1. **Configure your inventory**
   ```bash
   # Edit inventory.ini with your node information
   vi inventory.ini
   ```

   Example:
   ```ini
   [all:vars]
   ansible_user=root
   ansible_ssh_private_key_file=~/.ssh/id_rsa
   ansible_python_interpreter=/usr/bin/python3
   pod_network_cidr=10.244.0.0/16

   [masters]
   k8s-master ansible_host=192.168.156.30

   [workers]
   k8s-worker1 ansible_host=192.168.156.31
   k8s-worker2 ansible_host=192.168.156.32
   k8s-worker3 ansible_host=192.168.156.33
   k8s-worker4 ansible_host=192.168.156.34
   ```

### Installation

#### Method 1: One-Click Installation (Recommended)
```bash
# Install entire cluster at once
./run-k8s-install.sh
```

#### Method 2: Step-by-Step Installation
```bash
# Step 1: Create users and SSH setup
ansible-playbook -i inventory.ini 01-user-create.yml

# Step 2: Install Kubernetes components
ansible-playbook -i inventory.ini 02-k8s-install.yml

# Step 3: Initialize cluster and join nodes
ansible-playbook -i inventory.ini 03-k8s-init-cluster.yml

# Step 4: Check cluster status
ansible-playbook -i inventory.ini 04-k8s-check-cluster.yml
```

## File Structure

```
├── inventory.ini              # Node information and variables
├── run-k8s-install.sh        # One-click installation script
├── 01-user-create.yml        # Creates kube user and sets up SSH keys
├── 02-k8s-install.yml        # Installs containerd, kubelet, kubeadm, kubectl
├── 03-k8s-init-cluster.yml   # Initializes master node and joins workers automatically
└── 04-k8s-check-cluster.yml  # Validates cluster installation and status
```

## Key Changes

### Network Plugin: Calico → Flannel
- **Reason**: Flannel is simpler and more stable than Calico
- **CIDR Configuration**: `10.244.0.0/16` (Flannel default)
- **Installation Source**: `https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml`

### Enhanced Cluster State Validation
- **Wait Logic**: Waits up to 10 minutes for all kube-system pods to reach Running state
- **Retry Mechanism**: 60 retries with 10-second intervals
- **Detailed Reporting**: Shows network plugin status and overall cluster health

## Configuration Example

Example `inventory.ini` file:
```ini
[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
pod_network_cidr=10.244.0.0/16    # Flannel default CIDR

[masters]
k8s-master ansible_host=192.168.156.30

[workers]
k8s-worker1 ansible_host=192.168.156.31
k8s-worker2 ansible_host=192.168.156.32
k8s-worker3 ansible_host=192.168.156.33
k8s-worker4 ansible_host=192.168.156.34
```

## Post-Installation Verification

After successful installation, you can verify the following:

```bash
# All nodes should be in Ready state
kubectl get nodes

# All system pods should be in Running state
kubectl get pods -n kube-system

# Check Flannel pods
kubectl get pods -n kube-system -l app=flannel
```

## Troubleshooting

### Common Issues

1. **Pods not reaching Running state**
   - 04-k8s-check-cluster.yml automatically waits for 10 minutes
   - Provides specific error messages on timeout

2. **Network connectivity issues**
   - Check firewall settings (ports 6443, 10250, 30000-32767)
   - Verify SELinux configuration

3. **Node join failures**
   - Check API server status on master node
   - Verify token expiration

### Manual Cluster Management

**Regenerate join token (for adding nodes):**
```bash
# Run on master node
kubeadm token create --print-join-command
```

**Check cluster status:**
```bash
kubectl cluster-info
kubectl get componentstatuses
kubectl top nodes  # after installing metrics-server
```

## License

This project is distributed under the MIT License.

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
