global.config = require 'config'
global.Log = require './src/util/log'
RestServer = require './src/server'

restify = require 'restify'

#run all jobs
job = require './src/models/job'
job.run()

status = require './src/models/status'
status.configure(__dirname + '/persister')

restServer = new RestServer();

restServer.listen config.get('port.monitor_app'), -> Log.info("Monitor app server started at port #{config.get('port.monitor_app')}.")