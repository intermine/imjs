###
# @source: /src/user.coffee
#
# The User class represents the authenticated user's profile
# information. It provides access to methods to read an manipulate
# a user's preferences.
#
# @author: Alex Kalderimis
###
root = exports ? this
if typeof exports is 'undefined'
    IS_NODE = false
    Deferred = root.jQuery.Deferred
    _ = root._
    if typeof root.console is 'undefined'
        root.console =
            log: ->
            error: ->
    if root.intermine is 'undefined'
        root.intermine = {}
    root = root.intermine
else
    IS_NODE = true
    Deferred = require('jquery-deferred').Deferred
    _ = require('underscore')._

class User

    constructor: (@service, {@username, @preferences}) ->
        @hasPreferences = @preferences?
        @preferences ?= {}

    setPreference: (key, value) ->
        if _.isString(key)
            data = {}
            data[key] = value
        else if not value?
            data = key
        else
            return Deferred().reject("bad-arguments", "Incorrect arguments to setPreference")
        @setPreferences(data)

    ##
    # Set one or more preferences, provided as an object.
    ##
    setPreferences: (prefs) -> @_do_pref_req prefs, 'POST'

    ##
    # Clear a preference.
    ##
    clearPreference: (key) -> @_do_pref_req {key: key}, 'DELETE'

    ## 
    # Clear all preferences.
    ##
    clearPreferences: () -> @_do_pref_req {}, 'DELETE'

    refresh: () -> @_do_pref_req {}, 'GET'

    # Simple utility to take the returned value from manageUserPreferences and
    # update the preferences property on this object.
    _do_pref_req: (data, method) ->
        @service.manageUserPreferences(method, data).done (prefs) => @preferences = prefs

root.User = User

