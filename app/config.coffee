passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
debug = require('debug')('meshblu-facebook-authenticator:config')

facebookOauthConfig =
  clientID: process.env.FACEBOOK_CLIENT_ID
  clientSecret: process.env.FACEBOOK_CLIENT_SECRET
  callbackURL: process.env.FACEBOOK_CALLBACK_URL
  passReqToCallback: true

class FacebookConfig
  constructor: ({@meshbluHttp, @meshbluJSON}) ->

  onAuthentication: (request, accessToken, refreshToken, profile, done) =>
    profileId = profile?.id
    fakeSecret = 'facebook-authenticator'
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator {authenticatorUuid, authenticatorName, @meshbluHttp}
    query = {}
    query[authenticatorUuid + '.id'] = profileId
    device =
      name: profile.name
      type: 'octoblu:user'

    getDeviceToken = (uuid) =>
      @meshbluHttp.generateAndStoreToken uuid, (error, device) =>
        device.id = profileId
        done null, device

    deviceCreateCallback = (error, createdDevice) =>
      return done error if error?
      getDeviceToken createdDevice?.uuid

    deviceFindCallback = (error, foundDevice) =>
      return getDeviceToken foundDevice.uuid if foundDevice?
      deviceModel.create
        query: query
        data: device
        user_id: profileId
        secret: fakeSecret
      , deviceCreateCallback

    deviceModel.findVerified query: query, password: fakeSecret, deviceFindCallback

  register: =>
    passport.use new FacebookStrategy facebookOauthConfig, @onAuthentication

module.exports = FacebookConfig
