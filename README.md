# Secure Global Media Delivery & Multi-Tier Cloud Architecture

## 📌 Project Overview
This repository contains production-grade, modular Infrastructure as Code (IaC) written in Terraform to deploy a highly secure, fault-tolerant, and low-latency two-tier web application on AWS. 

The architecture is explicitly designed around the **Principle of Least Privilege** and **Defense in Depth**, ensuring that backend compute assets are entirely isolated from the public internet while static assets are globally optimized.

---

## 🗺️ System Architecture Diagram
![System Architecture Blueprint](./images/architecture-topology.png)

---

## 🛠️ Core Architectural Features

### 🌐 Global Content Delivery & Security Edge
* **Amazon CloudFront:** Serves as the public-facing edge network, providing low-latency caching at global edge locations and handling centralized SSL/TLS termination.
* **Origin Access Control (OAC):** Static media assets (`/images/*`) are locked down inside a private Amazon S3 bucket. All direct public S3 URLs are disabled; the bucket is hard-hardened to **only** accept traffic signed by the CloudFront Service Principal.

### 🔒 Strict Network Isolation (VPC Design)
The network topology is split across two separate Availability Zones (AZs) in the `ap-southeast-1` (Singapore) region to ensure high availability:
* **Public Tier:** Houses a public-facing Application Load Balancer (ALB) distributing traffic across multiple AZs. This is the *only* component exposed to the internet.
* **Private Tier:** Completely isolates the EC2 instances running Apache web servers. These instances have **no public IP addresses** and cannot be reached directly from the internet, mitigating automated brute-force attacks.

### 🚀 Internal Routing & Cost Optimization
* **S3 VPC Gateway Endpoint:** Instead of forcing private EC2 instances to route out to the public internet to download application assets from S3, traffic is routed through an internal Gateway Endpoint. This ensures data stays entirely within the secure AWS backbone network and eliminates data exfiltration charges.

---

## 🧰 Tools & Technologies
* **Infrastructure as Code:** Terraform (HCL) for predictable, repeatable state management.
* **Cloud Infrastructure:** Amazon Web Services (VPC, EC2, S3, CloudFront, ALB, IAM).
* **Design & Documentation:** Draw.io for architectural mapping.

---

## 🔒 Security Hardening Highlights (The "Why")
1. **No Static Access Keys:** The EC2 instances utilize dynamic, short-lived credentials via an IAM Instance Profile to fetch local configuration scripts, removing the risk of credential leakage.
2. **Asymmetric Security Groups:** The private EC2 tier utilizes strict ingress rules that *only* accept HTTP traffic originating specifically from the security group of the Application Load Balancer.
