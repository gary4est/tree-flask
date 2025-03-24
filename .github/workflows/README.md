# GitHub Workflows

This directory contains GitHub Actions workflows for testing, building, and deploying the application.

## Workflows

### `test-and-release.yml`

Main workflow for testing and deploying to the staging environment.

- **Triggers**: Pull requests to main, pushes to main, or manual dispatch
- **Jobs**:
  - `py_test`: Runs Python tests
  - `staging`: Builds and pushes container image to staging registry
  - `monitor_deployment`: Monitors FluxCD deployment status in staging

### `production.yml`

Workflow for deploying to the production environment.

- **Triggers**: Release published
- **Jobs**:
  - `production`: Builds and pushes container image to production registry
  - `monitor_deployment`: Monitors FluxCD deployment status in production

### `fluxcd-deployment-check.yml`

Reusable workflow for monitoring FluxCD deployment status. Used by both staging and production workflows.

- **Type**: Reusable workflow (not triggered directly)
- **Purpose**: Verifies that a FluxCD-based deployment completes successfully
- **Verification Steps**:
  1. Image Detection: Checks if the image is in ACR
  2. Policy Evaluation: Skipped (verified indirectly)
  3. Manifest Update: Verifies HelmRelease is updated and ready
  4. Git Commit and Push: Skipped (happens in Flux controllers)
  5. Source Detection: Confirms Git repositories are ready
  6. Manifest Reconciliation: Confirms HelmRelease is reconciled
  7. Resource Creation: Verifies pods are running
  8. Status Reporting: Checks app readiness and services

## Usage

To use the `fluxcd-deployment-check.yml` in a workflow, add a job like this:

```yaml
jobs:
  # Your previous jobs...
  
  monitor_deployment:
    name: FLUXCD_DEPLOYMENT_STATUS
    needs: [your-image-build-job]
    uses: ./.github/workflows/fluxcd-deployment-check.yml
    with:
      environment: staging # or production
      app_name: your-app-name
      namespace: your-namespace
      image_tag: ${{ needs.your-image-build-job.outputs.image_tag }}
      registry: your-registry.azurecr.io
      image_name: your-image-name
      aks_resource_group: your-resource-group
      aks_cluster_name: your-cluster-name
      max_attempts: 5 # Optional, default: 5
      sleep_seconds: 20 # Optional, default: 20
      subscription_id: ${{ vars.AZURE_SUBSCRIPTION_ID }} # Use AZURE_SUBSCRIPTION_CLUSTER_ID for staging
```

## Required GitHub Variables

For the workflows to function properly, you need to set up these GitHub variables:

- **Variables**:
  - `AZURE_CLIENT_ID`: Azure client ID for OIDC authentication
  - `AZURE_TENANT_ID`: Azure tenant ID for OIDC authentication
  - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID for production
  - `AZURE_SUBSCRIPTION_CLUSTER_ID`: Azure subscription ID for staging cluster
  - `MIQ_GHA_TOKEN`: GitHub token with appropriate permissions
  - `JIRA_SERVER`: Jira server URL (if using Jira integration)

- **Secrets**:
  - `JIRA_TOKEN`: Token for Jira integration (if used)
  - `MIQ_GHA_TOKEN`: GitHub token with appropriate permissions 