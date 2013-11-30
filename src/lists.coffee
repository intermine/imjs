# This module supplies the **List** class for the **im.js**
# web-service client.
#
# Lists are representations of collections of objects stored
# on the server.
#
# This library is designed to be compatible with both node.js
# and browsers.

utils = require './util'
intermine = exports

{merge, withCB, get, invoke, REQUIRES_VERSION, set, dejoin} = utils

TAGS_PATH = "list/tags"
SHARES = "lists/shares"
INVITES = 'lists/invitations'

isFolder      = (t) -> t.substr(0, t.indexOf(':')) is '__folder__'
getFolderName = (t) -> t.substr(t.indexOf(':') + 1)

# A representation of collections of objects stored in a data-warehouse.
#
# Lists can be created through the list upload mechanism (Service#createList) and
# the query saving mechanism (Query#saveAsList).
class List

  # Construct a new list.
  #
  # @param [Object] properties The properties of this list.
  # @option properties [String] name The name of this list.
  # @option properties [Number] size The size of this list.
  # @option properties [Number] dateCreated The timestamp of the creation date for this list.
  # @option properties [String] description The description of this list.
  # @option properties [tags] The tags for this list.
  # @param [Service] service The service this list belongs to.
  constructor: (properties, @service) ->
    for own k, v of properties
      @[k] = v
    @dateCreated = if (@dateCreated?) then new Date(@dateCreated) else null
    @folders = @tags.filter(isFolder).map(getFolderName)

  # Whether or not this list has a certain tag.
  #
  # @param [String] t The tag this list is meant to have.
  # @return [boolean] true if this list has the certain tag.
  hasTag: (t) => t in @tags

  # Construct a query for data contained in this list.
  #
  # @param [Array<String>] view An optional list of output columns.
  #   Defaults to the summary fields for objects of this type.
  # @return [Promise<Query>] A promise to yield a query.
  query: (view = ['*']) -> @service.query select: view, from: @type, where: [[@type, 'IN', @name]]

  # Delete this list on the server. The list should not be subsequently used.
  #
  # @param [->] cb An optional callback, called upon successful deletion.
  # @return [Promise<?>] A promise to delete the list.
  del: (cb) -> @service.makeRequest 'DELETE', 'lists', {@name}, cb

  getTags = ({tags}) -> tags

  _updateTags: (err, tags) =>
    return if err?
    @tags = tags.slice()
    @folders = @tags.filter(isFolder).map(getFolderName)

  # Get the current set of tags for this list, and update this object so it reflects the
  # current state of the server.
  #
  # @param [(Array<String>) ->] cb An optional callback
  # @return [Promise<Array<String>>] A promise to yield a list of tags.
  fetchTags: (cb) ->
    withCB @_updateTags, cb, @service.makeRequest('GET', 'list/tags', {@name}).then getTags

  # Add the given tags to the current set of tags for this list, and update this object so it
  # reflects the current state of the server.
  #
  # @param [Array<String>] tags The tags to add.
  # @param [(Array<String>) ->] cb An optional callback
  # @return [Promise<Array<String>>] A promise to yield a list of tags.
  addTags: (tags, cb) ->
    req = {@name, tags}
    withCB @_updateTags, cb, @service.makeRequest('POST', 'list/tags', req).then getTags

  # Remove the given tags from the current set of tags for this list, and update this object so it
  # reflects the current state of the server.
  #
  # @param [Array<String>] tags The tags to remove.
  # @param [(Array<String>) ->] cb An optional callback
  # @return [Promise<Array<String>>] A promise to yield a list of tags.
  removeTags: (tags, cb) ->
    req = {@name, tags}
    withCB @_updateTags, cb, @service.makeRequest('DELETE', 'list/tags', req).then getTags
  
  # Get the contents of this list.
  #
  # The dejoin function is used to ensure that all objects in the list are returned, and
  # we don't miss out on any due to the implicit constraints of inner joins.
  #
  # @param [(Array<Object>) ->] cb A function that receives a list of objects. Optional.
  # @return [Promise<Array<Object>>] A promise to yield a list of objects.
  contents: (cb) -> withCB cb, @query().then(dejoin).then(invoke 'records')

  # Rename this list. Upon resolution of this actions promise, this object will have its
  # name property set to the new value.
  #
  # @param [String] newName The name this list should have.
  # @param [(List) ->] cb An optional callback.
  # @return [Promise<List>] A promise to yield the new state of the list.
  rename: (newName, cb) ->
    req = oldname: @name, newname: newName
    withCB cb, @service.post('lists/rename', req)
                       .then(get 'listName')
                       .then((n) => @name = n)
                       .then(@service.fetchList)

  # Copy this list to an exact duplicate with a different name.
  #
  # This function will check that any name given does not collide with any other
  # list you have access to, adding a suffix to avoid name clashes. This means you should
  # probably check the yielded value to see what name it ended up with.
  #
  # @param [Object|String] opts Either an options object specifying the parameters
  #   for this operation, or the name to copy this list as.
  # @option opts [String] name The name for the copy. If a list already exists with this name
  #   then a number will be added to the name to make it unique. (optional,
  #   defaults to @name + _copy.)
  # @option opts [Array<String>] tags Tags to apply to the new list. These tags will be in
  #   addition to any that the list currently has, which will be copied over. (optional)
  # @param [(List) ->] cb An optional function that receives a List.
  # @return [Promise<List>] A promise to yield a list.
  copy: (opts = {}, cb = (->)) ->
    # Allow calling with copy(name, [cb]) and copy(cb)
    if arguments.length is 1 and utils.isFunction opts
      [opts, cb] = [{}, opts]
    if typeof opts is 'string'
      opts = name: opts

    name = baseName = (opts.name ? "#{ @name }_copy")
    tags = @tags.concat opts.tags ? []
    query = @query ['id']
    withCB cb, @service.fetchLists().then(invoke 'map', get 'name').then (names) =>
      c = 1
      while name in names
        name = "#{ baseName }-#{ c++ }"
      query.then(invoke 'saveAsList', {name, tags, @description})

  # Fetch the results for a particular enrichment calculation
  # against this list. See Service#enrichment.
  #
  # @param [Object] opts The parameters of this request.
  # @option opts [String] widget The calculation to run.
  # @option opts [Number] maxp The maximum permissible p-value (optional, default = 0.05).
  # @option opts [String] correction The correction algorithm to use (default = Holm-Bonferroni).
  # @option opts [String] population The name of a list to use as a background
  #   population (optional).
  # @option opts [String] filter An extra value that some widget calculations accept.
  # @param [->] cb A function to call with the results when they have been received (optional).
  # @return [Promise<Array<Object>>] A promise to get results.
  enrichment: (opts, cb) -> @service.enrichment (merge {list: @name}, opts), cb

  # Share this list with a recipient.
  #
  # The recipient should exist as a user in the target InterMine instance.
  #
  # @param [String] recipient The identifier of a user.
  # @param [->] cb A function to call on successful completion (optional).
  # @return [Promise<>] A promise to share a List.
  shareWithUser: (recipient, cb) ->
    # TODO - tests
    withCB cb, @service.post(SHARES, 'list': @name, 'with': recipient)

  # Invite a user to share this list.
  #
  # @param [String] recipient The email address of someone to invite to share this list.
  # @param [boolean] notify Whether or not to notify the recipient by email.
  # @param [->] cb A function to call upon successful completion.
  #
  # @return [Promise<>] A promise to invite a user to share a list.
  inviteUserToShare: (recipient, notify = true, cb = (->)) ->
    # TODO - tests
    withCB cb, @service.post(INVITES, list: @name, to: recipient, notify: !!notify)

intermine.List = List

