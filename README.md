---
# Tree App

Test app for CI/CD Workflow, with tox unit tests, health check and sample Jenkins CICD pipeline

[Documentation](docs/)

## GitHub Branch Source Plugin
The GitHub Branch Source Plugin is used to connect Jenkins and Github together. Once the GitHub Branch Source Plugin is enabled in Jenkins, follow these steps to set it up.

[GitHub Branch Source Plugin Documentation](https://go.cloudbees.com/docs/cloudbees-documentation/cje-user-guide/index.html#github-branch-source)

1. Setup the Webhook for Jenkins in your Github Repo.

In Github, under the Settings for you Github Repo go to Webhooks and add a new Webhook with the following:

**Payload URL**: https://JENKINS_SERVER_URL/github-webhook/

**Content type**: application/x-www-from-urlencoded

**Secret**: blank -- authentication will be setup later

**SSL verification**: Enable SSL verification

**Which events would you like to trigger this webhook**? -- Let me select individual events (Pull requests)

**Note**: In this example we chose to use Pull requests to kick off a new build, many options are available. 

2. Create a Github Organization in Jenkins.

Under the main Jenkins URL https://JENKINS_SERVER_URL/ choose [New Item](https://JENKINS_SERVER_URL/view/all/newJob) 

**Enter Item Name**: Tree

**Type**: GitHub Organization

3. Configuration of the GitHub Organization

**Projects**: Create credentials to access Github

**Filter by name**: tree* *In this examnple we only want Repos that start with tree*

### Documentation

[Build and Deploy only on Merge to Master](docs/DeployOnMergeToMaster.md)

[Build and Deploy on all branches Pull Requests](docs/DeployOnPrPush.md)

[Build on PR with Changes, Deploy on Merge to Master only](docs/BuildOnPrDeployOnMergeToMasterOnly.md)







