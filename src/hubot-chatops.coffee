# Description:
#   Hubot plugin for devops
#
# Configuration:
#   DEPLOYER_URL - URL of deployer
#   HUBOT_URL - URL of hubot itself
#   GITHUB_TOKEN - Personal access token of user who can clone the repos
#
# Commands:
# hubot stage <branch name> of <github user or org>/<repository name>

module.exports = (robot) ->

  chatops_deployer_url = process.env.DEPLOYER_URL
  hubot_url = process.env.HUBOT_URL
  github_token = process.env.GITHUB_TOKEN

  stage = (repoName, branchName, res) ->
    room = if robot.adapterName == 'slack' then res.message.room else res.message.user.reply_to

    repo = "https://#{github_token}@github.com/#{repoName}.git"
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
          res.send "Okay, I'll deploy `#{branchName}` branch of '#{repoName}' to staging.#{log_message}"

  robot.respond /stage (.*) of (.*)/i, (res) ->
    branchName = res.match[1]
    repoName = res.match[2]
    stage(repoName, branchName, res)

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
    res.send 'OK'
