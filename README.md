# Profertility — Cloud-Native Fertility Care & Telemedicine Platform

A production-grade, microservices-based digital health and fertility consultation platform deployed on **AWS EKS** using **Terraform**, **Kubernetes Gateway API (NGINX Gateway Fabric)**, **Cert-Manager (Let's Encrypt TLS)**, and **GitOps continuous delivery via Argo CD**.

---

## Architecture Overview

<div align="center">

![Architecture Diagram](https://cdn.mojasim.com/1787731565072-Profertility-Diagram.png)

*End-to-end cloud infrastructure, Gateway API routing, and microservices communication topology on AWS EKS*

</div>

### Traffic Flow & Networking
1. **Edge & Load Balancing:** Incoming HTTPS traffic across all public endpoints (`mojasim.tech`, `api.mojasim.tech`, `admin.mojasim.tech`, `plus.mojasim.tech`) reaches an **AWS Network Load Balancer (NLB)** provisioned automatically by **NGINX Gateway Fabric**.
2. **Kubernetes Gateway API & TLS Termination:** The Kubernetes `Gateway` resource (`profertility-gateway`) manages centralized HTTP (Port 80) and HTTPS (Port 443) listeners. **Cert-Manager** automatically issues, validates, and rotates production SSL/TLS certificates via **Let's Encrypt** HTTP-01 challenge solvers integrated directly with Gateway API routes.
3. **Host-Based Route Dispatching:** Declarative `HTTPRoute` resources route decrypted traffic across the private cluster network to dedicated `ClusterIP` Kubernetes services:
   - `mojasim.tech` $\rightarrow$ `profertility-client` (Port 3000)
   - `api.mojasim.tech` $\rightarrow$ `profertility-backend` (Port 7005)
   - `admin.mojasim.tech` $\rightarrow$ `profertility-admin` (Port 4173)
   - `plus.mojasim.tech` $\rightarrow$ `profertility-plus` (Port 3001 $\rightarrow$ 3000)
4. **Service Communication & Data Layer:** Frontend applications communicate with the backend REST API over HTTPS/CORS. The backend microservice interacts with MongoDB Atlas over encrypted TLS connections, synchronizes real-time telemedicine streams with Agora RTC, coordinates asynchronous file storage with Cloudflare R2, and processes payments and webhooks with Stripe.

---

## Application Previews

| Customer Web Portal | Clinic Admin Dashboard | Profertility Plus Portal |
| :---: | :---: | :---: |
| ![Patient Web Portal](https://cdn.mojasim.com/Profertility.png) | ![Admin Dashboard](https://cdn.mojasim.com/1776674021386-Profertility-User-Dashboard.png) | ![Profertility Plus Portal](https://cdn.mojasim.com/ProfertilityPlus.png) |
| **Next.js Patient Portal**<br>Fertility assessments, appointment booking, telehealth calls, and care journeys | **React & Vite Admin Dashboard**<br>Specialist scheduling, patient records, timetable management, and analytics | **Next.js Plus Program Portal**<br>Specialized IVF protocols, curated wellness plans, and waitlist onboarding |

---

## Microservices Directory

| Service | Description | Tech Stack | Repository |
| :--- | :--- | :--- | :--- |
| **Backend API Engine** | Central REST API engine handling authentication, patient medical profiles, appointments, doctor schedules, video rooms, and payment billing | Node.js, Express, MongoDB Atlas, Mongoose, JWT, Agora SDK, Stripe API | [profertility-backend](https://github.com/mo-jasim/profertility-backend) |
| **Patient Web Portal** | Primary patient-facing web application for interactive fertility quizzes, doctor consultations, care packages, and tele-health sessions | Next.js (App Router), React, TypeScript, Tailwind CSS | [profertility-client](https://github.com/mo-jasim/profertility-client) |
| **Admin & Clinical Dashboard** | Clinical operations portal for fertility specialists, nurses, and administrators to manage patient records, bookings, slots, and content | React 18, Vite, TypeScript, Tailwind CSS, Lucide Icons, Axios | [profertility-admin](https://github.com/mo-jasim/profertility-admin) |
| **Profertility Plus Portal** | Dedicated high-conversion digital portal for premium fertility programs, AI quiz evaluations, and specialized clinical protocols | Next.js (App Router), React, TypeScript, Tailwind CSS | [profertility-plus](https://github.com/mo-jasim/profertility-plus) |
| **Infrastructure & GitOps** | Infrastructure as Code (Terraform) and Kubernetes Gateway API deployment manifests managed declaratively via Argo CD | Terraform, AWS EKS, Gateway API, NGINX Gateway Fabric, Cert-Manager, Argo CD | [profertility-deployment](https://github.com/mo-jasim/profertility-deployment) |

---

## Datastores & External Services

- **MongoDB Atlas:** High-availability cloud document database storing patient records, specialist profiles, appointment slots, quiz responses, blogs, and orders.
- **Agora RTC Engine:** Ultra-low latency real-time video/audio communication platform powering encrypted live telehealth and patient-doctor consultations.
- **Cloudflare R2 Storage:** High-performance, S3-compatible object storage for secure distribution of medical reports, patient documentation, and platform media.
- **Stripe API:** Payment processing engine managing one-time consultation payments, tiered fertility subscriptions (monthly & 6-month plans), and secure webhook lifecycle handling.
- **Hostinger SMTP:** Enterprise transactional mailer handling automated booking confirmations, patient onboarding reminders, and clinic enquiries.
- **Google Cloud APIs:** Google OAuth 2.0 single sign-on authentication and Google Calendar integration for doctor schedule synchronization.

---

## Infrastructure & GitOps Deployment

### Infrastructure as Code (Terraform)
The AWS cloud architecture is automated using modular **Terraform** configurations located in [`terraform/`](./terraform):
- **AWS VPC:** Custom VPC spanning 3 Availability Zones with dedicated public (`10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`), private (`10.0.4.0/24`, `10.0.5.0/24`, `10.0.6.0/24`), and intra (`10.0.7.0/24`, `10.0.8.0/24`, `10.0.9.0/24`) subnets with active NAT Gateways.
- **AWS EKS Cluster:** Managed Kubernetes (v1.35) cluster featuring managed node groups (`t3a.medium`, desired: 2, max: 3), EBS CSI Driver via IRSA (IAM Roles for Service Accounts), and EKS Pod Identity.
- **NGINX Gateway Fabric:** Modern Kubernetes Gateway API controller (`v1.4.0`) installed via Helm to manage routing policies and external AWS Load Balancers.
- **Cert-Manager:** Automated TLS lifecycle management (v1.14.4) with experimental Gateway API support and Let's Encrypt Production ClusterIssuer.
- **Argo CD:** Production GitOps engine provisioned in the `argocd` namespace for continuous state synchronization.

### CI/CD & Deployment Flow
- **Continuous Integration (GitHub Actions):** Pushing code to `main` across service repositories triggers automated pipelines to validate code quality, build multi-architecture Docker containers, and publish tagged images to Docker Hub (`mojasim/profertility-*`).
- **GitOps Continuous Delivery (Argo CD):** Argo CD monitors this deployment repository and continuously reconciles Kubernetes manifests (`Gateway`, `HTTPRoute`, `Deployment`, `Service`, `Secret`) against the target AWS EKS cluster.
- **High Availability & Zero Downtime:** Kubernetes Deployments utilize rolling updates and decoupled secrets management, ensuring continuous platform uptime during version rollouts.

---

## Repository Structure

```text
├── admin/                      # Kubernetes manifests for Admin Dashboard
│   ├── deployment.yml          # Container deployment spec (port 4173)
│   ├── route.yml               # Gateway API HTTPRoute for admin.mojasim.tech
│   ├── service.yml             # ClusterIP service definition
│   └── secrets.yml.example     # Secret template (API & dashboard endpoints)
├── backend/                    # Kubernetes manifests for Backend REST API
│   ├── deployment.yml          # Container deployment spec (port 7005)
│   ├── route.yml               # Gateway API HTTPRoute for api.mojasim.tech
│   ├── service.yml             # ClusterIP service definition
│   └── secrets.yml.example     # Secret template (Database, Stripe, SMTP, JWT)
├── client/                     # Kubernetes manifests for Patient Portal
│   ├── deployment.yml          # Container deployment spec (port 3000)
│   ├── route.yml               # Gateway API HTTPRoute for mojasim.tech
│   ├── service.yml             # ClusterIP service definition
│   └── secrets.yml.example     # Secret template (API URLs, discount codes)
├── gateway/                    # Gateway API & TLS Ingress Infrastructure
│   ├── cluster-issuer.yml      # Let's Encrypt ACME ClusterIssuer
│   ├── gateway.yml             # Multi-host Gateway resource (HTTP & HTTPS)
│   └── namespace.yml           # Core application namespace (profertility)
├── profertility-plus/          # Kubernetes manifests for Profertility Plus
│   ├── deployment.yml          # Container deployment spec (port 3000)
│   ├── route.yml               # Gateway API HTTPRoute for plus.mojasim.tech
│   ├── service.yml             # ClusterIP service definition (port 3001 -> 3000)
│   └── secrets.yml.example     # Secret template (API endpoints)
└── terraform/                  # Terraform Infrastructure as Code
    ├── eks.tf                  # AWS EKS cluster & IRSA node groups
    ├── vpc.tf                  # Multi-AZ VPC networking configuration
    ├── argocd.tf               # Argo CD, Gateway Fabric & Cert-Manager Helm releases
    ├── provider.tf             # AWS and Helm Terraform providers
    ├── variables.tf            # Configurable Terraform variables
    ├── outputs.tf              # EKS endpoints & kubectl helper outputs
    └── terraform.tfvars.example# Variables configuration template
```

---

## Getting Started

### 1. Provision Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Update variables as needed
terraform init
terraform apply
```

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --region ap-south-1 --name profertility-eks
```

### 3. Deploy Kubernetes Secrets
Copy and populate all secret files locally from their example templates:
```bash
cp admin/secrets.yml.example admin/secrets.yml
cp backend/secrets.yml.example backend/secrets.yml
cp client/secrets.yml.example client/secrets.yml
cp profertility-plus/secrets.yml.example profertility-plus/secrets.yml

kubectl apply -f gateway/namespace.yml
kubectl apply -f gateway/gateway.yml
kubectl apply -f gateway/cluster-issuer.yml

kubectl apply -f admin/
kubectl apply -f backend/
kubectl apply -f client/
kubectl apply -f profertility-plus/
```

---

## Architecture Diagram Prompt (for AI Design Tools)

To generate an architecture diagram matching this project (e.g. using Eraser.io, Napkin.ai, DALL-E, Midjourney, Claude, or ChatGPT), use the following prompt:

```text
Create a clean, modern, high-resolution cloud architecture diagram for a production telemedicine and digital health platform named "Profertility" deployed on AWS EKS.

1. Users & Edge Layer:
   - External Users / Patients accessing via domain (mojasim.tech), Doctors / Admins accessing (admin.mojasim.tech), API clients accessing (api.mojasim.tech), and Plus Program users (plus.mojasim.tech).
   - Traffic flows into an AWS Network Load Balancer (NLB) with TLS encryption.

2. AWS VPC & Kubernetes Cluster (AWS EKS v1.35 in Region ap-south-1):
   - Multi-AZ VPC with Public Subnets, Private Subnets (Worker Nodes on t3a.medium EC2 instances), and Intra Subnets.
   - NGINX Gateway Fabric (Kubernetes Gateway API Controller) acting as the ingress router.
   - Cert-Manager v1.14.4 automatically handling Let's Encrypt TLS certificates (ClusterIssuer) via HTTP-01 challenges.
   - Gateway Resource (profertility-gateway) distributing traffic via HTTPRoutes to 4 internal ClusterIP services:
     * profertility-client (Next.js Patient Portal, Port 3000)
     * profertility-admin (React + Vite Admin Dashboard, Port 4173)
     * profertility-plus (Next.js Plus Program Portal, Port 3001)
     * profertility-backend (Node.js/Express REST API Engine, Port 7005)

3. Backend Microservice Integrations & External Services:
   - profertility-backend connects to:
     * MongoDB Atlas (Cloud Database for patient data, medical records, appointments, quiz scores)
     * Agora RTC Cloud (Real-time encrypted video/audio consultations between patients and specialists)
     * Cloudflare R2 (S3-compatible storage for medical reports and media)
     * Stripe Payment Gateway (Consultation fees and recurring fertility subscriptions)
     * Hostinger SMTP Server (Transactional emails and appointment notifications)
     * Google OAuth & Calendar APIs (Single Sign-On and doctor schedule sync)

4. GitOps & CI/CD Layer:
   - GitHub Repositories (backend, admin, client, plus, deployment)
   - GitHub Actions building multi-arch Docker images to Docker Hub
   - Argo CD running in the EKS cluster continuously synchronizing Git manifests to Kubernetes.

Style: Sleek dark mode / tech theme, isometric or modern 2D topology with clear arrows, service logos (AWS, EKS, Kubernetes, NGINX, Argo CD, MongoDB, Stripe, Agora), crisp labels, and clean color-coded boundaries.
```
