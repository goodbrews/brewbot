# Description:
#   Receive webhooks from BreweryDB
#
# Dependencies:
#   "querystring": "0.1.0"
#
# Configuration:
#   BREWERYDB_API_KEY - your BreweryDB webhook URL
#   BREWERYDB_WEBOOK_ROOM - room to send announcements to
#
# Commands:
#   None
#
# URLs:
#   POST /hubot/brewerydb/webhooks/:type
#
# Authors:
#   davidcelis

crypto = require 'crypto'
qs = require 'querystring'

module.exports = (robot) ->

  robot.router.post "/hubot/brewerydb/webhooks/:type", (req, res) ->
    user = { room: process.env.BREWERYDB_WEBOOK_ROOM }
    unless process.env.BREWERYDB_API_KEY?
      robot.send(user, "We got an update from BreweryDB, but BREWERYDB_API_KEY isn't set!")

    query = qs.parse(req._parsedUrl.query)
    nonce = query.nonce
    key = query.key

    if key == crypto.createHash('sha1').update(process.env.BREWERYDB_API_KEY + nonce)
      attribute        = query.attribute
      attribute_id     = query.attributeId
      action           = query.action.replace(/(\w+)e?$/, "$1ed")
      sub_action       = query.subAction if query.subAction
      sub_attribute_id = query.subAttributeId if query.subAttributeId
      url = "http://www.brewerydb.com/#{attribute}/#{attribute_id}"

      message = "We just got an update from BreweryDB! A"
      message += "n" if attribute == "event"
      message += "#{attribute} was #{action}. See #{url} for more info"
      message += " (specifically, this was a #{sub_action})"
      message += "."

      robot.send(user, message)

      if robot.adapter.bot?.Room?
        robot.adapter.bot.Room(user.room).sound "trombone", (err, data) =>
          console.log "campfire error: #{err}" if err

      res.end "Webhook notification sent"
