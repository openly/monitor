moment = require 'moment'

class Log
  constructor: (@logtoConsole=true) ->
    @loggers = []

  addLogger: (logger)->
    @loggers.push logger

  clearLoggers: ()->
    @loggers = []

  info: (text)->
    @log "INFO", text

  warn: (text)->
    @log "WARN", text

  debug: (text)->
    @log "DEBUG", text

  error: (text)->
    text = text.message + '\n' + text.stack + '\n' if text instanceof(Error)
    @log "ERROR", text

  log: (loglevel, text)->
    logText = "[#{moment().format('DD-MM-YYYY HH:mm:ss')}] #{loglevel}: #{text}"

    console.log logText if @logtoConsole

    logger.log logText for logger in @loggers

module.exports = new Log