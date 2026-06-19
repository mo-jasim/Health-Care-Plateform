# Profertility EKS Deployment Guide 🚀

This guide provides the exact steps and commands needed to provision the EKS infrastructure and deploy the application manifests, Gateway API, and ArgoCD.

## 1. Apply the Infrastructure (Terraform)
Since Terraform manages the base infrastructure (EKS cluster, ArgoCD, Gateway API CRDs, Cert-Manager, and NGINX Gateway Fabric), you must apply it first.

```bash
cd terraform
terraform init
terraform apply -auto-approve
cd ..
```

## 2. Update Kubeconfig
Once the cluster is up, update your local Kubeconfig to interact with the new cluster:

```bash
aws eks update-kubeconfig --region ap-south-1 --name profertility-eks
```

## 3. Apply Kubernetes Manifests
Apply the application manifests in the following order:

```bash
# 1. Create the Namespace FIRST
kubectl apply -f gateway/namespace.yml

# 2. Apply the Gateway and Cluster Issuer
kubectl apply -f gateway/gateway.yml
kubectl apply -f gateway/cluster-issuer.yml

# 3. Apply Application Manifests (Secrets first, then the rest)
# Backend
kubectl apply -f backend/secrets.yml
kubectl apply -f backend/service.yml
kubectl apply -f backend/deployment.yml
kubectl apply -f backend/route.yml

# Admin
kubectl apply -f admin/secrets.yml
kubectl apply -f admin/service.yml
kubectl apply -f admin/deployment.yml
kubectl apply -f admin/route.yml

# Client
kubectl apply -f client/secrets.yml
kubectl apply -f client/service.yml
kubectl apply -f client/deployment.yml
kubectl apply -f client/route.yml

# Profertility Plus
kubectl apply -f profertility-plus/secrets.yml
kubectl apply -f profertility-plus/service.yml
kubectl apply -f profertility-plus/deployment.yml
kubectl apply -f profertility-plus/route.yml
```

## 4. Get the AWS Load Balancer URL (Gateway API)
To get the Load Balancer hostname that AWS provisions for your NGINX Gateway, run:

```bash
kubectl get svc -n nginx-gateway -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}'
```
*(You will point your DNS records—like `mojasim.tech` and `api.mojasim.tech`—to this Load Balancer URL).*

## 5. Access ArgoCD Locally (Port Forwarding)
ArgoCD is configured with Ingress disabled (ClusterIP only). To securely access it locally, use port-forwarding:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
After running this, open your browser and navigate to: **https://localhost:8080**

## 6. Get the ArgoCD Admin Password
To log in to the ArgoCD UI, the default username is `admin`. Run the following command to retrieve the auto-generated password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
