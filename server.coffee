express = require 'express'
morgan = require 'morgan'
bodyParser = require 'body-parser'
errorHandler = require 'errorhandler'
cookieParser = require 'cookie-parser'
session = require 'express-session'
passport = require 'passport'
Router = require './app/routes'
Config = require './app/config'
meshblu = require 'meshblu'
debug = require('debug')('meshblu-facebook-authenticator:server')

port = process.env.MESHBLU_FACEBOOK_AUTHENTICATOR_PORT ? 8008

app = express()
app.use morgan('dev')
app.use errorHandler()
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use cookieParser()

app.use session
  secret: 'super awesome cool secret'
  resave: false
  saveUninitialized: true

app.use passport.initialize()
app.use passport.session()

passport.serializeUser (user, done) =>
  done null, user.id

passport.deserializeUser (user, done) =>
  done null, user

app.engine 'html', require('ejs').renderFile

app.set 'view engine', 'html'

app.set 'views', __dirname + '/app/views'

try
  meshbluJSON  = require './meshblu.json'
catch
  meshbluJSON =
    uuid:   process.env.MESHBLU_FACEBOOK_AUTHENTICATOR_UUID
    token:  process.env.MESHBLU_FACEBOOK_AUTHENTICATOR_TOKEN
    name:   process.env.MESHBLU_FACEBOOK_AUTHENTICATOR_NAME
    server: process.env.MESHBLU_HOST
    port:   process.env.MESHBLU_PORT


meshbluConn = meshblu.createConnection meshbluJSON

meshbluConn.on 'ready', =>
  debug 'Connected to meshblu'

  meshbluConn.whoami {}, (device) ->
    meshbluConn.setPrivateKey(device.privateKey) unless meshbluConn.privateKey

  app.listen port, =>
    debug "Meshblu Facebook Authenticator..."
    debug "Listening at localhost:#{port}"

    config = new Config meshbluConn, meshbluJSON
    config.register()

    router = new Router app
    router.register()

meshbluConn.on 'notReady', =>
  debug 'Unable to connect to meshblu'


