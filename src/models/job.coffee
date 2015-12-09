schedule = require 'node-schedule'
async = require 'async'
moment = require 'moment'
request = require 'request'

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
    #every 15 min once
    interval = '* * * * *'
    j = schedule.scheduleJob(interval, @monitorSites.bind(@))
    return cb.apply @, [null]

  monitorSites: (cb)->
    sites = config.get('sites')
    
    monitorEachSite = (site, asyncCb)=>
      request site.url, (err, resp, body)=>
        if resp?.statusCode isnt 200 or err?.code is 'ECONNREFUSED'
          @sendMessageToSlack(site)
        
        return asyncCb(null)

    async.eachSeries sites, monitorEachSite, (err)=>
      if err?
        Log.error err.message
      else
        Log.info "monitored all the configured sites."
          
      return cb.apply @, [err] if cb?


  sendMessageToSlack: (details)->
    qsData = {
      token:details.slack.token,
      channel:details.slack.channel,
      username:details.slack.username,
      icon_emoji:details.slack.icon_emoji,
      text:details.slack.text
    }
    data = {
      url: config.get('slack_api_url'),
      qs: qsData,
      method: 'POST'
    }
    request data, (err, resp, body)->
      Log.error err.message if err?
      Log.info "Message sent to #{details.slack.channel} - #{details.name}"
    return


job = new Job
module.exports = job