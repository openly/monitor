restify = require 'restify'

class RestAPIServer
  constructor: () ->
    @server = restify.createServer()
    @server.on('uncaughtException', @_unhandledException)

  listen: (port, callback)->
    @server.listen port, callback

  _unhandledException: (req, res, next, err)->
    Log.error err
    return if res.headersSent?
    return res.json(new restify.InternalError(err.message))

module.exports = RestAPIServer