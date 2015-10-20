hubot-chatops
=============

A hubot plugin for devops.

Currently it integrates with [chatops_deployer](https://github.com/code-mancers/chatops_deployer)
to deploy and destroy disposable environments.

### Configuration

    DEPLOYER_URL - URL of chatops_deployer
    HUBOT_URL - URL of hubot itself

### Commands

    @bot deploy feature-branch of github_org/reponame # Deploys
    @bot destroy feature-branch of github/org/reponame # Destroys deployment

### License
MIT
