bot = require 'mock-hubot'
script = require '../src/hubot-chatops.coffee'
nock = require 'nock'

describe 'hubot-chatops', ->
  beforeEach (done) ->
    # Initialize mock-hubot and load the hubot script
    bot.start ->
      bot.learn script
      nock("#{process.env.DEPLOYER_URL}")
        .post('/deploy')
        .reply 200, { log_url: 'http://example.com/log' }
        .post('/destroy')
        .reply 200, {}
      done()

  afterEach (done) ->
    bot.shutdown ->
      done()

  describe 'command to deploy', ->
    it 'responds with the right message for gihub repo name', (done) ->
      bot.test("hubot deploy test of organization/project").then (response) ->
        expect(response.toString())
          .toEqual("Okay, I'll deploy `test` branch of 'organization/project'. Check deployment logs here: http://example.com/log")
        done()
    it 'responds with the right message for gitlab repo url', (done) ->
      bot.test("hubot deploy test of git@your_server.com:organization/project.git").then (response) ->
        expect(response.toString())
          .toEqual("Okay, I'll deploy `test` branch of 'git@your_server.com:organization/project.git'. Check deployment logs here: http://example.com/log")
        done()

  describe 'command to destroy', ->
    it 'responds with the right message for github repo name', (done) ->
      bot.test("hubot destroy test of organization/project").then (response) ->
        expect(response.toString())
          .toEqual("Okay, I'll destroy environment for `test` of 'organization/project'.")
        done()
    it 'responds with the right message for gitlab repo url', (done) ->
      bot.test("hubot destroy test of git@your_server.com:organization/project.git").then (response) ->
        expect(response.toString())
          .toEqual("Okay, I'll destroy environment for `test` of 'git@your_server.com:organization/project.git'.")
        done()
