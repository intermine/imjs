# This module supplies the **List** class for the **im.js**
# web-service client.
#
# Lists are representations of collections of objects stored
# on the server.
#
# This library is designed to be compatible with both node.js
# and browsers.

IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

if IS_NODE
    {_} = require 'underscore'
    {invoke} = require './util'
    intermine = __root__
else
    {_, intermine}  = __root__
    {invoke}        = intermine.funcutils

TAGS_PATH = "list/tags"
SHARES = "lists/shares"
INVITES = "lists/invitations"

isFolder = (t) -> t.substr(0, t.indexOf(':')) is '__folder__'
getFolderName = (t) -> s.substr(t.indexOf(':') + 1)

class List

    constructor: (properties, @service) ->
        for own k, v of properties
            @[k] = v
        @dateCreated = if (@dateCreated?) then new Date(@dateCreated) else null

        @folders = @tags.filter(isFolder).map(getFolderName)

    hasTag: (t) -> t in @tags

    del: (cb) -> @service.makeRequest 'DELETE', 'lists', {@name}, cb

    contents: (cb) -> @service.query(select: ['*'], from: @type, where: [[@type, 'IN', @name]])
                              .pipe(invoke 'records')
                              .done(cb)

    enrichment: (opts, cb) -> @service.enrichment((set list: @name) opts, cb)

    shareWithUser: (recipient, cb) ->
        @service.post(SHARES, list: @name, with: recipient).done(cb)

    inviteUserToShare: (recipient, notify, cb) ->
        @service.post(INVITES, list: @name, to: recipient, notify: !!notify).done(cb)

intermine.List = List





