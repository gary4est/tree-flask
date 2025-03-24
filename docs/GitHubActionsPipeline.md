# GitHub Actions CI/CD Pipeline

This document describes the CI/CD pipeline implemented with GitHub Actions for the Flask application.

## Workflow Overview

The GitHub Actions workflow is defined in `.github/workflows/test-and-release.yml` and consists of the following jobs:

### 1. Python Testing (py_test)

This job:
- Sets up Python 3.12
- Installs dependencies
- Runs tests on the Flask application
- Verifies that all endpoints work correctly

### 2. Docker Image Build (staging)

This job:
- Authenticates with Azure
- Logs in to Azure Container Registry (ACR)
- Builds the Docker image with the correct version information
- Pushes the image to ACR

### 3. Deployment Monitoring (monitor_deployment)

This job:
- Authenticates with the Azure Kubernetes Service (AKS) cluster
- Monitors the deployment status
- Verifies that the HelmRelease is ready
- Confirms that the deployment is using the expected image

## Triggering the Pipeline

The pipeline is triggered on:
- Pull requests to the main branch
- Pushes to the main branch
- Manual workflow dispatch

## Environment Variables

The following environment variables are used:
- Azure credentials for authentication
- Registry information for the Docker image
- Kubernetes cluster details for deployment monitoring

## Deployment Process

The application is deployed using FluxCD, which automatically detects the new image in the container registry and updates the deployment in Kubernetes. 