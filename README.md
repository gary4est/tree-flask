---
# Tree App

Test app for CI/CD Workflow, with tox unit tests, health check and GitHub Actions workflow

[Documentation](docs/)

## CI/CD with GitHub Actions

This project uses GitHub Actions for continuous integration and continuous deployment. The workflow is defined in the `.github/workflows/test-and-release.yml` file.

The workflow includes:

1. Running tests on a Flask application
2. Building and pushing a Docker image to Azure Container Registry
3. Monitoring the deployment to Kubernetes with FluxCD

### Documentation

Documentation regarding the CI/CD process:

- [GitHub Actions CI/CD Pipeline](docs/GitHubActionsPipeline.md)







