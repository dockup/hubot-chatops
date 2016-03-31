# Description:
#   Hubot plugin for devops
#
# Configuration:
#   DEPLOYER_URL - URL of deployer
#   HUBOT_URL - URL of hubot itself
#
# Commands:
#   hubot deploy <branch name> of <github user or org>/<repository name> - Deploy a branch from a github repo
#   hubot destroy <branch name> of <github user or org>/<repository name> - Destroy an existing environment deployed for a branch of a github repo

module.exports = (robot) ->
  chatops_deployer_url = process.env.DEPLOYER_URL
  hubot_url = process.env.HUBOT_URL

  # Function that sends API request to chatops_deployer to deploy
  # a github repository and a branchname. It provides a callback_url
  # to be triggered once deployment is ready.
  # As the response it accepts a log_url. If this parameter is available,
  # a friendly message is posted to chat with this log URL.
  deploy = (repoName, branchName, res) ->
    room = if robot.adapterName == 'hipchat' then res.message.user.reply_to else res.message.room
    repo = repo(reponame)

    data = JSON.stringify({
      repository: repo,
      branch: branchName,
      callback_url: "#{hubot_url}/chatops/callback/#{room}"
    })
    robot.http("#{chatops_deployer_url}/deploy")
      .header('Content-Type', 'application/json')
      .post(data) (err, response, body) ->
        if(err)
          res.send("Cannot reach chatops_deployer. Is it running on #{chatops_deployer_url} ?")
          robot.logger.log(err)
        else
          log_url = JSON.parse(body)['log_url']
          log_message =  if log_url then " Check deployment logs here: #{log_url}" else ""
          res.send "Okay, I'll deploy `#{branchName}` branch of '#{repoName}'.#{log_message}"

  # Funtion that sends the API request to chatops_deployer to destroy
  # the environment for a given github repo and branchname
  destroy = (repoName, branchName, res) ->
    room = if robot.adapterName == 'hipchat' then res.message.user.reply_to else res.message.room
    repo = repo(reponame)

    data = JSON.stringify({
      repository: repo,
      branch: branchName,
      callback_url: "#{hubot_url}/chatops/callback/#{room}"
    })
    robot.http("#{chatops_deployer_url}/destroy")
      .header('Content-Type', 'application/json')
      .post(data) (err, response, body) ->
        if(err)
          res.send("Cannot reach chatops_deployer. Is it running on #{chatops_deployer_url} ?")
          robot.logger.log(err)
        else
          console.log(body)
          res.send "Okay, I'll destroy environment for `#{branchName}` of '#{repoName}'."

  robot.respond /deploy (.*) of (.*)/i, (res) ->
    branchName = res.match[1]
    repoName = res.match[2]
    deploy(repoName, branchName, res)

  robot.respond /destroy (.*) of (.*)/i, (res) ->
    branchName = res.match[1]
    repoName = res.match[2]
    destroy(repoName, branchName, res)

  robot.router.post '/chatops/callback/:room', (req, res) ->
    room   = req.params.room
    data   = req.body
    status = data.status
    branch = data.branch
    switch status
      when 'deployment_failure'
        robot.messageRoom room, "Sorry, cannot deploy branch `#{branch}`. Reason: #{data.reason}"
      when 'deployment_success'
        robot.messageRoom room, "Deployed `#{branch}` : #{data.urls}"
      when 'destroy_success'
        robot.messageRoom room, "Destroyed environment for `#{branch}`"
      when 'destroy_failure'
        robot.messageRoom room, "Could not destroy environment for `#{branch}`"

    res.send 'OK'

  repo = (repoName) ->
    if (repoName.match(/.*[:\/](.*)\/(.*).git/)) then repoName else "https://github.com/#{repoName}.git"
