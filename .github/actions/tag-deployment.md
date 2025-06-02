# Automatic tagging for deployment versioning
This workflow computes a version tag with a format compliant with [Web.Autoの稼働中バージョン可視化](https://tier4.atlassian.net/wiki/spaces/WEB/pages/3650062459/Web.Auto) and pushes the tag to the ref that the workflow was invoked with.

It assumes that a mainline branch to from where new releases are cut exists, by default this branch is assumed to be called `develop`. You can configure it, if yours is called differently.

## Usage

### 1. Add a workflow to tag references that are deployed. 
In the example below, all pushes to `develop`, `master`, and `release`, respectively are deployed with via git ops so we also tag on pushes to those branches.

**Inputs:**

|Argument|Description|
|--|--|
|dev-branch | **Optional string.** Specify an alternate branch name for the main-line development branch from where releases are cut.|
|suffix | **Optional string.** If present will be added at the end of the tag name like `-suffix`. This is a convenience for the usecase where you have one git-ops flow per subcomponent. If you deploy all the subcomponents from the same workflow (e.g. via a deployment script) it's better to leave this empty and set the subcomponent in the deployment script.|


**Example:**

```yaml
name: Tag on Release

on:
  push:
    branches:
      - develop
      - master
      - release

jobs:
  tag-release:
    permissions:
      contents: write # We push a tag, write permissions are required.
    uses: tier4/WebAutoIaCGitHubActions/.github/workflows/tag-deployment.yml@main
    with:
      dev-branch: 'develop2'
```

### 2. Use the tag when deploying to push 
Make sure that tags are fetched by your CI/CD pipeline and get the tag for the ref you're deploying:

```bash
VERSION_TAG=$(git tag --points-at HEAD | grep -P "^\d{4}-\d{2}-\d{2}-p\d+-.*\$")
[ "$VERSION_TAG" ] || { echo "No version tag for current ref!"; exit 1; }
```

Then pass that tag to your AWS deployment command make sure the template sets the tag properly to the relevant resources.

Something like:

```bash
aws cloudformation deploy ... --tags Version=$VERSION_TAG-core ...
aws cloudformation deploy ... --tags Version=$VERSION_TAG-event ...
```
