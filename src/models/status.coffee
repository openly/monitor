fs = require 'fs-extra'

class Status

  configure: (statusPath)->
    @statusPath = statusPath
  
  getStatus : (appName)=>
    filePath = "#{@statusPath}/status.json"
    try
      statuses = fs.readJsonSync filePath
      return statuses[appName] if statuses[appName]?
      return ''
    catch e
      return ''

  setStatus : (appName, status)=>
    status = '' unless status?

    appName = appName.toLowerCase().replace(/\ /g, "_")
    filePath = "#{@statusPath}/status.json"
    try
      statuses = fs.readJsonSync filePath
    catch e
      statuses = {}
    
    statuses[appName] = status
    try
      fs.outputJsonSync filePath, statuses
    catch e
     e.Message = "Not able to save status for #{appName}" + e.Message
     throw e    
  
  isStatusChanged : (appName, newStatus)=>
    newStatus = '' unless newStatus?
    appName = appName.toLowerCase().replace(/\ /g, "_")
    oldStatus = @getStatus appName
    return (oldStatus isnt newStatus)

status = new Status
module.exports = status