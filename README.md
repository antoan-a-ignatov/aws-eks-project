# AWS EKS Cloud Native Platform

## Project Status
In progress. Day X of 5 complete.

## Introduction
Short description of what this project is, what problem it demonstrates a solution for, and who it is built for (context: portfolio project targeting a Senior DevOps Engineer role focused on AWS and Kubernetes).

## Table of Contents
- Skills Demonstrated
- Architecture
- Repository Structure
- Technology Stack
- CI/CD Pipeline
- Security
- Engineering Challenges and Design Decisions
- Planned Improvements

## Skills Demonstrated
List of core skills this project demonstrates, ideally mapped to the target job posting.

## Architecture
Architecture diagram and a short walkthrough of how the pieces fit together.

## Repository Structure
Explanation of the folder layout and what lives where.

## Technology Stack
List of the tools and services used, grouped by category (IaC, CI/CD, orchestration, secrets, messaging, automation, monitoring, logging).

## CI/CD Pipeline
Explanation of the pipeline flow from commit to deployment, including the stages involved.

## Security

### Secrets Management
How secrets flow from AWS Secrets Manager through External Secrets Operator into the cluster, and why plaintext or inline secrets are never used.

### IAM and Access Control
Approach to least privilege IAM roles, including IRSA and pipeline access into the cluster.

### Network Exposure
How the application is exposed, and what is or is not publicly reachable.

## Engineering Challenges and Design Decisions
Notable problems encountered, trade offs made, and why certain choices were made over alternatives.

## Planned Improvements
Things intentionally left out of scope for this project, with reasoning, such as Vault or Doppler, service mesh, Route53.
