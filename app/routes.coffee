passport = require 'passport'
debug = require('debug')('meshblu-facebook-authenticator:routes')
url = require 'url'

class Router
  constructor: (@app) ->

  register: =>
    @app.get  '/', (request, response) => response.status(200).send status: 'online'

    @app.get '/login', @storeCallbackUrl, passport.authenticate 'facebook', scope: ['public_profile', 'email']

    @app.get '/oauthcallback', passport.authenticate('facebook', { failureRedirect: '/login' }), @afterPassportLogin

  afterPassportLogin: (request, response) =>
    {callbackUrl} = request.cookies
    response.cookie 'callbackUrl', null, maxAge: -1
    return response.status(401).send(new Error 'Invalid User') unless request.user
    return response.status(201).send(request.user) unless callbackUrl?
    uriParams = url.parse callbackUrl
    uriParams.query ?= {}
    uriParams.query.uuid = request.user.uuid
    uriParams.query.token = request.user.token
    return response.redirect(url.format uriParams)

  defaultRoute: (request, response) =>
    response.render 'index'

  storeCallbackUrl: (request, response, next) =>
    if request.query.callbackUrl?
      response.cookie 'callbackUrl', request.query.callbackUrl, maxAge: 60 * 60 * 1000
    else
      response.cookie 'callbackUrl', null, maxAge: -1
    next()

module.exports = Router
