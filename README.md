# kubernetes
# Kubernetes — Quick Command Reference

A cheat-sheet of common commands for creating and managing an **Amazon
EKS** cluster and working with it via `kubectl`, used while developing
and testing the **ai-kubernetes-agent** project.

---

## 1. Prerequisites

Install these on your EC2 box (or local machine) before creating a cluster:

#install aws cli

```bash
# Update packages
sudo apt update

# Install curl and unzip
sudo apt install -y curl unzip

# Download AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Extract the installer
unzip awscliv2.zip

# Install AWS CLI
sudo ./aws/install

# Verify installation
aws --version
```

# Insttall  kubectl
```
# Download the latest stable kubectl binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable
chmod +x kubectl

# Move it to your PATH
sudo mv kubectl /usr/local/bin/

# Verify the installation
kubectl version --client
```


# Install eksctl (simplest way to create/manage EKS clusters)
```
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```
or
```
# Download the latest eksctl release
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"

# Extract the binary
tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp

# Install eksctl
sudo mv /tmp/eksctl /usr/local/bin

# Verify the installation
eksctl version

Make sure AWS credentials are configured:
```
#aws configure

```bash
AWS Access Key ID [None]: <YOUR_ACCESS_KEY_ID>
AWS Secret Access Key [None]: <YOUR_SECRET_ACCESS_KEY>
Default region name [None]: us-east-1
Default output format [None]: json
```

---

## 2. Cluster creation (EKS)

### Create a basic EKS cluster with a managed node group

```bash
# basic-cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: iata-cluster
  region: us-east-1
  version: "1.34"

nodeGroups:
  - name: worker-nodes
    instanceType: c7i-flex.large
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
    volumeSize: 20
    privateNetworking: true
    ssh:
      allow: false
```
command to create an eks cluster

```bash
eksctl create cluster -f basic-cluster.yaml
```

> This takes ~15-20 minutes — EKS provisions the control plane, VPC,
> and worker nodes.

### Create a cluster using a config file (more control, repeatable)

```yaml
# cluster-config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ai-k8s-agent
  region: ap-south-1

nodeGroups:
  - name: ai-k8s-agent-nodes
    instanceType: t3.medium
    desiredCapacity: 2
    minSize: 1
    maxSize: 3
```

```bash
eksctl create cluster -f cluster-config.yaml
```

### Check cluster creation status

```bash
eksctl get cluster --region ap-south-1
```

### List clusters via AWS CLI directly

```bash
aws eks list-clusters --region ap-south-1
```

### Describe a specific cluster

```bash
aws eks describe-cluster --name ai-k8s-agent --region ap-south-1
```

---

## 3. Connect kubectl to the cluster

```bash
aws eks update-kubeconfig --region ap-south-1 --name cluster-name
```

### Verify connection

```bash
kubectl cluster-info
kubectl get nodes
```

---

## 4. Basic cluster health commands

```bash
# Node status
kubectl get nodes

# Node status with more detail (IP, OS, kubelet version)
kubectl get nodes -o wide

# Cluster component health
kubectl get componentstatuses
```

---

## 5. Basic pod commands

```bash
# List pods in default namespace
kubectl get pods

# List pods in all namespaces
kubectl get pods --all-namespaces

# Check if a specific pod exists
kubectl get pod <pod-name>

# Watch pod status live
kubectl get pods --watch

# Detailed pod info (events, restarts, conditions)
kubectl describe pod <pod-name>

# Pod logs
kubectl logs <pod-name>

# Logs from a previous (crashed) container
kubectl logs <pod-name> --previous
```

---

## 6. Basic deployment & service commands

```bash
# List deployments
kubectl get deployments

# Check rollout status
kubectl rollout status deployment/<deployment-name>

# List services
kubectl get services

# List all resources at once
kubectl get all
```

---

## 7. Events (debugging)

```bash
# Recent events, sorted by time
kubectl get events --sort-by=.metadata.creationTimestamp

# Events in a specific namespace
kubectl get events -n <namespace>
```

---

## 8. Namespace commands

```bash
# List namespaces
kubectl get namespaces

# Create a namespace
kubectl create namespace <namespace-name>

# Delete a namespace
kubectl delete namespace <namespace-name>
```

---

## 9. Cleanup

### Delete a pod

```bash
kubectl delete pod <pod-name>
```

### Delete a deployment

```bash
kubectl delete deployment <deployment-name>
```

### Delete the entire EKS cluster (stops billing for control plane + nodes)

```bash
eksctl delete cluster --name ai-k8s-agent --region ap-south-1
```

> Always delete the cluster when you're done testing — EKS bills
> ~$0.10/hour for the control plane alone, plus EC2 costs for worker
> nodes.

---

## Notes

- Region used above is `ap-south-1` (Mumbai) — swap for whichever
  region you provision in.
- `eksctl` handles VPC, subnets, and IAM roles automatically. If you
  already have a VPC (e.g. from your Terraform project), you can pass
  `--vpc-private-subnets` / `--vpc-public-subnets` to reuse it instead
  of creating a new one.
