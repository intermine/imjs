# @source: /src/user.coffee
#
# The User class represents the authenticated user's profile
# information. It provides access to methods to read an manipulate
# a user's preferences.
#
# @author: Alex Kalderimis

{withCB, get, isFunction, any, error}    = require './util'
intermine                                = exports

# Simple utility to take the returned value from manageUserPreferences and
# update the preferences property on this object.
do_pref_req = (user, data, method, cb) ->
  user.service.manageUserPreferences(method, data, cb).then (prefs) -> user.preferences = prefs

# A representation of the user we are logged in as.
class User

  # Save references to the service, as well as
  # extracting the user's preferences from the options.
  #
  # @param [intermine.Service] service the connection to the webservice
  # @param [Object] options The data used to instantiate this object
  # @option options [String] username The user's log-in name
  # @option options [Object] preferences A key-value mapping of the preferences this user has set.
  #
  constructor: (@service, {@username, @preferences}) ->
    @hasPreferences = @preferences?
    @preferences ?= {}

  # Set a given preference.
  #
  # @param [String] key The key to set.
  # @param [String] value The value to set.
  # @return [Deferred] a promise to set a preference.
  setPreference: (key, value, cb) =>
    if isFunction value
      [value, cb] = [null, value]
    if typeof key is 'string'
      data = {}
      data[key] = value
    else if not value?
      data = key
    else
      return withCB cb, error "Incorrect arguments to setPreference"
    @setPreferences(data, cb)

  # Set one or more preferences, provided as an object.
  setPreferences: (prefs, cb) =>
    do_pref_req @, prefs, 'POST', cb

  # Clear a preference.
  clearPreference: (key, cb) => do_pref_req @, {key: key}, 'DELETE', cb

  # Clear all preferences.
  clearPreferences: (cb) => do_pref_req @, {}, 'DELETE', cb

  refresh: (cb) => do_pref_req @, {}, 'GET', cb

  createToken: (type = 'day', message, cb) ->
    if not cb? and any [type, message], isFunction
      if isFunction type
        [type, message, cb] = [null, null, type]
      else if isFunction message
        [message, cb] = [null, message]
    withCB cb, @service.post('user/tokens', {type, message}).then(get 'token')

  fetchCurrentTokens: (cb) ->
    withCB cb, @service.get('user/tokens').then(get 'tokens')

  revokeAllTokens: (cb) ->
    withCB cb, @service.makeRequest('DELETE', 'user/tokens')

  revokeToken: (token, cb) ->
    withCB cb, @service.makeRequest('DELETE', "user/tokens/#{ token }")

intermine.User = User

