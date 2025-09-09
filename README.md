# Ansible Kubernetes Installation for Rocky Linux 9

This repository contains Ansible playbooks for automated installation and configuration of Kubernetes clusters on Rocky Linux 9.

## Features

- **Network Plugin**: Flannel (simple and stable)
- **Fully Automated**: One-click installation script provided
- **State Validation**: Waits until core system pods (kube-system + kube-flannel) are in Running state
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
   token_ttl=24h

   [masters]
   k8s-master ansible_host=192.168.156.30

   [workers]
   k8s-worker1 ansible_host=192.168.156.31
   k8s-worker2 ansible_host=192.168.156.32
   k8s-worker3 ansible_host=192.168.156.33
   k8s-worker4 ansible_host=192.168.156.34
   ```

## Configuration Variables

All configuration variables are defined in the `[all:vars]` section of `inventory.ini`. You can customize these values according to your environment requirements.

### Required Variables

| Variable | Description | Default | Examples |
|----------|-------------|---------|----------|
| `ansible_user` | SSH user for connecting to nodes | `root` | `root`, `admin`, `centos` |
| `ansible_ssh_private_key_file` | Path to SSH private key | `~/.ssh/id_rsa` | `~/.ssh/id_rsa`, `/path/to/key` |
| `ansible_python_interpreter` | Python interpreter path on target nodes | `/usr/bin/python3` | `/usr/bin/python3` |

### Network Configuration

| Variable | Description | Default | Examples |
|----------|-------------|---------|----------|
| `pod_network_cidr` | Pod network CIDR for Flannel | `10.244.0.0/16` | `10.244.0.0/16`, `10.100.0.0/16` |

**Note**: If you change `pod_network_cidr`, ensure it doesn't conflict with your existing network infrastructure.

### Security Settings

| Variable | Description | Default | Examples |
|----------|-------------|---------|----------|
| `token_ttl` | Kubernetes join token expiration time | `24h` | `1h`, `30m`, `7d`, `0` |

**Token TTL Examples:**
- `30m` - 30 minutes (for testing environments)
- `2h` - 2 hours (for security-conscious environments)
- `24h` - 24 hours (default, balanced approach)
- `7d` - 7 days (for environments requiring longer token validity)
- `0` - Never expires (NOT RECOMMENDED for security reasons)

### Complete Configuration Example

```ini
[all:vars]
# SSH Connection Settings
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

# Network Configuration
pod_network_cidr=10.244.0.0/16

# Security Settings
token_ttl=24h

[masters]
k8s-master ansible_host=192.168.156.30

[workers]
k8s-worker1 ansible_host=192.168.156.31
k8s-worker2 ansible_host=192.168.156.32
k8s-worker3 ansible_host=192.168.156.33
k8s-worker4 ansible_host=192.168.156.34
```

### Environment-Specific Examples

#### Production Environment
```ini
[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/prod_key
ansible_python_interpreter=/usr/bin/python3
pod_network_cidr=10.244.0.0/16
token_ttl=2h  # Shorter TTL for security
```

#### Development Environment
```ini
[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/dev_key
ansible_python_interpreter=/usr/bin/python3
pod_network_cidr=10.100.0.0/16  # Different CIDR to avoid conflicts
token_ttl=7d  # Longer TTL for convenience
```

#### Testing Environment
```ini
[all:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/test_key
ansible_python_interpreter=/usr/bin/python3
pod_network_cidr=10.200.0.0/16
token_ttl=30m  # Short TTL for frequent testing
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
├── reset-k8s-cluster.sh      # Complete reset script (removes everything)
├── 99-reset-k8s-cluster.yml  # Complete reset playbook
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
- **Wait Logic**: Waits up to 10 minutes for core system pods (kube-system + kube-flannel) to reach Running state
- **Retry Mechanism**: 60 retries with 10-second intervals
- **Detailed Reporting**: Shows network plugin status and overall cluster health

## Post-Installation Verification

After successful installation, you can verify the following:

```bash
# Run on master node
# All nodes should be in Ready state
kubectl get nodes

# Core system pods should be in Running state
kubectl get pods -n kube-system

# Check Flannel pods (in kube-flannel namespace)
kubectl get pods -n kube-flannel
```

## Troubleshooting

### Common Issues

1. **Core system pods not reaching Running state**
   - 04-k8s-check-cluster.yml automatically waits for 10 minutes for kube-system and kube-flannel pods
   - Provides specific error messages on timeout
   - User application pods are not included in this validation

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
# Run on master node
kubectl cluster-info
kubectl get componentstatuses
kubectl top nodes  # after installing metrics-server
```

## License

This project is distributed under the MIT License.

**Get discovery hash:**
```bash
# Run on master node
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | \
  openssl rsa -pubin -outform der 2>/dev/null | \
  openssl dgst -sha256 -hex | \
  sed 's/^.* //'
```

### Cluster Status Check

**Check nodes:**
```bash
# Run on master node
kubectl get nodes
kubectl get pods -A
```

## Worker Node Management

### Adding New Worker Nodes

The playbooks support automatic addition of new worker nodes. Follow these steps:

#### 1. Prepare the New Node
- Ensure the new node runs Rocky Linux 9
- Configure SSH access from the control machine
- Ensure the node meets hardware requirements

#### 2. Update Inventory
Add the new worker node to `inventory.ini`:
```ini
# Edit on Ansible control machine
[workers]
k8s-worker1 ansible_host=192.168.156.31
k8s-worker2 ansible_host=192.168.156.32
k8s-worker3 ansible_host=192.168.156.33
k8s-worker4 ansible_host=192.168.156.34
k8s-worker5 ansible_host=192.168.156.35  # New node
k8s-worker6 ansible_host=192.168.156.36  # New node
k8s-worker7 ansible_host=192.168.156.37  # New node
```

#### 3. Run Installation Playbooks
Execute the playbooks to automatically configure and join the new node:
```bash
# Run on Ansible control machine
# Option 1: Run all playbooks (recommended)
./run-k8s-install.sh

# Option 2: Run specific playbooks
ansible-playbook -i inventory.ini 01-user-create.yml
ansible-playbook -i inventory.ini 02-k8s-install.yml
ansible-playbook -i inventory.ini 03-k8s-init-cluster.yml
```

#### 4. Verify New Node
```bash
# Run on master node
kubectl get nodes
kubectl get pods -o wide  # Check pod distribution
```

**Note**: Existing nodes will be skipped automatically due to idempotency checks in the playbooks.

### Removing Worker Nodes

Worker node removal requires manual intervention to ensure safe migration of workloads.

#### 1. Pre-removal Checklist
- Verify cluster has sufficient capacity for workload migration
- Check for any persistent volumes or stateful applications on the target node
- Ensure no critical system pods are exclusively running on the target node

#### 2. Drain the Node
```bash
# Run on master node
# Replace <node-name> with the actual node name from 'kubectl get nodes'
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force

# Example:
kubectl drain k8s-worker5 --ignore-daemonsets --delete-emptydir-data --force
kubectl drain k8s-worker6 --ignore-daemonsets --delete-emptydir-data --force
kubectl drain k8s-worker7 --ignore-daemonsets --delete-emptydir-data --force
```

#### 3. Remove from Cluster
```bash
# Run on master node
# Remove the node from Kubernetes cluster
kubectl delete node <node-name>

# Example:
kubectl delete node k8s-worker5
kubectl delete node k8s-worker6
kubectl delete node k8s-worker7
```

#### 4. Clean up the Physical Node
Log into the worker node and reset Kubernetes configuration:
```bash
# Run on the worker node being removed
sudo kubeadm reset --force

# Clean up network interfaces (Flannel)
sudo rm -rf /var/lib/cni/
sudo rm -rf /etc/cni/
sudo ip link delete cni0 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true

# Optional: Remove Kubernetes packages
sudo dnf remove -y kubelet kubeadm kubectl containerd
```

#### 5. Update Inventory
Remove the node from `inventory.ini`:
```ini
# Edit on Ansible control machine
[workers]
k8s-worker1 ansible_host=192.168.156.31
k8s-worker2 ansible_host=192.168.156.32
k8s-worker3 ansible_host=192.168.156.33
k8s-worker4 ansible_host=192.168.156.34
# k8s-worker5 ansible_host=192.168.156.35  # Removed
# k8s-worker6 ansible_host=192.168.156.36  # Removed
# k8s-worker7 ansible_host=192.168.156.37  # Removed
```

#### 6. Verify Removal
```bash
# Run on master node
kubectl get nodes
kubectl get pods -o wide  # Verify workloads redistributed
```

### Emergency Node Recovery

If a node becomes unresponsive:

```bash
# Run on master node
# Force remove from cluster (use with caution)
kubectl delete node <node-name> --force --grace-period=0

# Clean up stuck resources
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node-name>
kubectl delete pods <pod-name> --force --grace-period=0 -n <namespace>
```

### Best Practices

1. **Planning**: Always plan node changes during maintenance windows
2. **Backup**: Ensure cluster and application backups before major changes
3. **Monitoring**: Monitor cluster resources during and after node changes
4. **Testing**: Test workload migration in non-production environments first
5. **Documentation**: Keep inventory.ini in sync with actual cluster state

## Complete Environment Reset

If you need to completely remove Kubernetes and reset all nodes to pre-installation state:

### Quick Reset (Recommended)
```bash
# Run on Ansible control machine
./reset-k8s-cluster.sh
```

### Manual Reset
```bash
# Run on Ansible control machine
ansible-playbook -i inventory.ini 99-reset-k8s-cluster.yml
```

### What Gets Reset

The reset process removes **everything** installed by the playbooks:

#### **Kubernetes Components**
- Cluster membership (kubeadm reset)
- All Kubernetes packages (kubelet, kubeadm, kubectl, containerd)
- Configuration directories (`/etc/kubernetes`, `/var/lib/kubelet`, etc.)
- systemd services and files

#### **Network Configuration**
- CNI network interfaces (cni0, flannel.1, docker0)
- Virtual ethernet interfaces (veth*)
- iptables rules (reset to defaults)
- Network plugin configurations

#### **System Configuration**
- Kernel modules (overlay, br_netfilter)
- sysctl settings (`/etc/sysctl.d/k8s.conf`)
- Repository files (kubernetes.repo, docker-ce.repo)
- Package caches

#### **User Account**
- 'kube' user account and home directory
- SSH authorized keys
- sudo privileges

#### **Local Files**
- `join-command.txt` (on control machine)
- `/etc/hosts` cluster entries

### After Reset

After running the reset:
1. All nodes return to clean Rocky Linux 9 state
2. Ready for fresh Kubernetes installation
3. Run `./run-k8s-install.sh` to reinstall

### Safety Features

- **Confirmation required**: Interactive confirmation before reset
- **Error handling**: Continues even if some operations fail
- **Detailed logging**: Shows what was removed on each node
5. **Documentation**: Keep inventory.ini in sync with actual cluster state
