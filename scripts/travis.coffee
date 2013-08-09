# Description:
#   Find the build status of an open-source project on Travis
#   Can also notify about builds, just enable the webhook notification on travis http://about.travis-ci.org/docs/user/build-configuration/ -> 'Webhook notification'
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_TRAVIS_TOKEN
#
# Commands:
#   hubot travis me <user>/<repo> - Returns the build status of https://github.com/<user>/<repo>
#
# URLS:
#   POST /hubot/travis?room=<room>[&type=<type]
#
# Author:
#   sferik
#   nesQuick
#   sergeylukin

url = require('url')
querystring = require('querystring')
gitio = require('gitio')
crypto = require('crypto');
key = process.env.HUBOT_TRAVIS_TOKEN

module.exports = (robot) ->

  robot.respond /travis me (.*)/i, (msg) ->
    project = escape(msg.match[1])
    msg.http("https://api.travis-ci.org/repos/#{project}")
      .get() (err, res, body) ->
        response = JSON.parse(body)
        if response.last_build_status == 0
          msg.send "Build status for #{project}: Passing"
        else if response.last_build_status == 1
          msg.send "Build status for #{project}: Failing"
        else
          msg.send "Build status for #{project}: Unknown"

  robot.router.post "/hubot/travis", (req, res) ->
    auth_header = req.headers['authorization']

    query = querystring.parse url.parse(req.url).query
    res.end JSON.stringify {
       received: true #some client have problems with and empty response
    }

    user = {}
    user.room = query.room if query.room
    user.type = query.type if query.type

    try
      payload = JSON.parse(req.body.payload)

      project = "#{payload.repository.owner_name}/#{payload.repository.name}"
      sha256 = crypto.createHash('sha256').update(project + key).digest('hex')

      if key && sha256 != auth_header
        console.log '"Travis" hook received from unknown origin. Or your Token is incorrect.'
        return

      build_status = payload.status_message.toUpperCase()
      build_url    = payload.build_url
      branch       = payload.branch
      commit_sha   = payload.commit.slice(0, 6)
      author       = payload.author_name
      compare_url  = payload.compare_url

      robot.send user, "Build #{build_status} (#{build_url}) on #{branch} with commit #{commit_sha} by #{author} (changes: #{compare_url})"

    catch error
      console.log "Travis hook error: #{error}. Payload: #{req.body.payload}"

