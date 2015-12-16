schedule = require 'node-schedule'
async = require 'async'
moment = require 'moment'
request = require 'request'
statusModel = require './status'

class Job
  
  run: ()->
    tasks = [@scheduleSiteMonitor.bind(@)]
    async.series tasks, (e)->
      if e?
        Log.error e
      else
        Log.info 'Jobs started successfully.'

  scheduleSiteMonitor: (cb)=>
    unless config.get('sites')?
      e = new Error ("Sites config is not set yet.")
      return cb.apply @, [e]
    
    unless config.get('slack_api_url')?
      e = new Error ("Slack api url is not set yet.")
      return cb.apply @, [e]

    unless config.get('interval')?
      e = new Error ("Cron job interval is not set yet.")
      return cb.apply @, [e]
    #every 15 min once
    interval = if config.get('interval')? then config.get('interval') else "*/15 * * * *"
    j = schedule.scheduleJob(interval, @monitorSites.bind(@))
    return cb.apply @, [null]

  monitorSites: (cb)->
    sites = config.get('sites')
    
    monitorEachSite = (site, asyncCb)=>
      request site.url, (err, resp, body)=>
        Log.info "#{site.name} is Up" if resp?.statusCode is 200
        Log.info "#{site.name} is Down" if resp?.statusCode isnt 200
        isStatusChanged = statusModel.isStatusChanged(site.name, resp?.statusCode)
        if isStatusChanged
          statusModel.setStatus(site.name, resp?.statusCode)
          @sendMessageToSlack site, resp?.statusCode, (e)->
            Log.error e
            return asyncCb(null)
        else
          return asyncCb(null)
    
    async.eachSeries sites, monitorEachSite, (err)=>
      if err?
        Log.error err.message
      else
        Log.info "monitored all the configured sites."
          
      return cb.apply @, [err] if cb?


  sendMessageToSlack: (details, statusCode, cb)->
    username = if details.slack.username? then details.slack.username else "Monitor"
    icon_emoji = if details.slack.icon_emoji? then details.slack.icon_emoji else ":monitor:"
    downMessage = "Looks like #{details.name} is down"
    upMessage = "#{details.name} is up and running"
    message = if statusCode isnt 200 then downMessage else upMessage
    text = if details.slack.text? then details.slack.text else message
    barColor = if statusCode isnt 200 then "#FF0033" else "#36a64f"
    
    attachment = []
    attachment. push {
      fallback: "Monitoring sites",
      author_name :"#{message}",
      title :"Click here to Navigate",
      title_link:details.url,
      color:barColor
    }

    qsData = {
      token:details.slack.token,
      channel:details.slack.channel,
      username:username,
      icon_emoji:icon_emoji,
      attachments: JSON.stringify(attachment)
    }

    data = {
      url: config.get('slack_api_url'),
      qs: qsData,
      method: 'POST'
    }
    request data, (err, resp, body)->
      Log.info "Message sent to #{details.slack.channel} - #{details.name}"
      return cb(err)


job = new Job
module.exports = job