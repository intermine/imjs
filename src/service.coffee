# This module supplies the **Service** class for the **im.js**
# web-service client.
#
# Services are representations of connections to a web-service.
# They abstract the transportation layer and the available
# resources of the InterMine API.
#
# This library is designed to be compatible with both node.js
# and browsers.
#

Promise           = require './promise'
{Model}           = require './model'
{Query}           = require './query'
{List}            = require './lists'
{User}            = require './user'
{IDResolutionJob} = require './id-resolution-job'
base64            = require './base64'
version           = require './version'
utils             = require './util'
http              = require './http'

to_query_string   = utils.querystring
{withCB, map, merge, get, set, invoke, success, error, REQUIRES_VERSION, dejoin} = utils

intermine = exports

# Set up all the private closed over variables
# that the service will want, but don't need
# exposing to the outside world.

# Cache resources that are meant to be stable.
# Stable resources do not change between releases
# of a service.
VERSIONS = {}
CLASSKEYS = {}
RELEASES = {}
MODELS = {}
SUMMARY_FIELDS = {}
WIDGETS = {}

# If the user doesn't add one on their
# url, assume HTTP.
DEFAULT_PROTOCOL = "http://"

# A list of endpoints exposed by the service.
VERSION_PATH = "version"
TEMPLATES_PATH = "templates"
RELEASE_PATH = "version/release"
CLASSKEY_PATH = "classkeys"
LISTS_PATH = "lists"
MODEL_PATH = "model"
SUMMARYFIELDS_PATH = "summaryfields"
QUERY_RESULTS_PATH = "query/results"
QUICKSEARCH_PATH = "search"
WIDGETS_PATH = "widgets"
ENRICHMENT_PATH = "list/enrichment"
WITH_OBJ_PATH = "listswithobject"
LIST_OPERATION_PATHS =
  union: "lists/union",
  intersection: "lists/intersect",
  difference: "lists/diff"
SUBTRACT_PATH = 'lists/subtract'
WHOAMI_PATH = "user/whoami"
TABLE_ROW_PATH = QUERY_RESULTS_PATH + '/tablerows'
PREF_PATH = 'user/preferences'
PATH_VALUES_PATH = 'path/values'
USER_TOKENS = 'user/tokens'
ID_RESOLUTION_PATH = 'ids'

NO_AUTH = {}
NO_AUTH[p] = true for p in [VERSION_PATH, RELEASE_PATH, CLASSKEY_PATH, WIDGETS_PATH
  MODEL_PATH, SUMMARYFIELDS_PATH, QUICKSEARCH_PATH, PATH_VALUES_PATH]
ALWAYS_AUTH = {}
ALWAYS_AUTH[p] = true for p in [WHOAMI_PATH, PREF_PATH, LIST_OPERATION_PATHS,
  SUBTRACT_PATH, WITH_OBJ_PATH, ENRICHMENT_PATH, TEMPLATES_PATH, USER_TOKENS]

NEEDS_AUTH = (path, q) ->
  if NO_AUTH[path]
    false
  else if ALWAYS_AUTH[path]
    true
  else if not q?.needsAuthentication
    true # Not configured, and no query info => default true.
  else
    q.needsAuthentication()

# Pattern for detecting if URI has a protocol
HAS_PROTOCOL = /^https?:\/\//i

# Pattern for detecting if the URI has the necessary service suffix.
HAS_SUFFIX = /service\/?$/i

# The suffix all service URIs must end in.
SUFFIX = "/service/"

# BY DEFAULT, LOG ERRORS TO THE CONSOLE.
DEFAULT_ERROR_HANDLER = (e) ->
  f = console.error ? console.log
  f e

# A private helper for a repeated pattern where
# we only fetch a piece of information if it is not
# already available in a instance or static cache.
# @private
# @param [String] propName The name of this property. A promise will be
#   set at this property.
# @param [Object] store The cache of things to check if we can use a cache.
# @param [String] path The path to GET from if we have to make a request.
# @param [String] key The property of the JSON response which has the value
#   that should be yielded to the user.
# @param [->] cb A callback that accepts this kind of thing. (optional)
_get_or_fetch = (propName, store, path, key, cb) ->
  {root, useCache} = @
  promise = @[propName] ?= if (useCache and value = store[root])
    success(value)
  else
    # Data property only needed for old mines..., eventually remove!
    opts = type: 'GET', dataType: 'json', data: {format: 'json'}
    @doReq(merge opts, url: @root + path).then (x) -> store[root] = x[key]

  withCB cb, promise

# A private helper that produces a function that will read
# through an array of Lists, and find the first one with the
# given name. The returned function returns a promise to find
# the given list, and will be rejected if no list of that name
# can be found.
# @param [String] name The name of the list to find.
# @return [([List]) -> Deferred.<List>] A function from an array of
#   List objects to a promise to return a List.
getListFinder = (name) -> (lists) -> new Promise (resolve, reject) ->
  if list = (utils.find lists, (l) -> l.name is name)
    resolve list
  else
    reject """List "#{ name }" not found among: #{ lists.map get 'name' }"""

LIST_PIPE = (service, prop = 'listName') -> utils.compose service.fetchList, get prop
TO_NAMES = (xs = []) -> (x.name ? x for x in (if utils.isArray(xs) then xs else [xs]))

# The representation of a connection to an InterMine web-service.
#
# The Service class is the entry-point into the imjs library,
# and the focal point for communication with the server. Connections
# to specific services are instantiated with reference to their
# base url and optional authentication information for accessing
# private user data. If data is required from more than one user at
# the same service, multiple connection objects should be instantiated,
# each authenticated to the appropriate user (requests that return
# data that can be cached between users will be made as most once, unless
# the service is connected with the 'noCache' option.
#
class Service

  doReq: http.doReq

  # Construct a new connection to a service.
  #
  # @param [Object] options The configuration information used by the service
  # @option options [String] root The base URL of the webservice (required). This
  #   is typically of the form "http://HOST/PATH", eg: "http://www.flymine.org/query"
  # @option options [String] token An authentication token (optional)
  # @option options [(err) ->] errorHandler A function that handles errors. (optional)
  #   If any errors occur when making HTTP calls to the server, the errors will
  #   be logged by this global error handler, which by default logs to the console.
  #   This can be changed by passing an alternative error handler, such as (->) to
  #   suppress error logging.
  # @option options [boolean] DEBUG Whether to log extra debug information (optional).
  # @option options [String] help An email address to show to the user if
  #   help is needed (optional).
  # @option options [boolean] noCache Set this flag to true to prevent the use of the global
  #   results caches for non-volatile data (models, versions, etc). Each service instance will
  #   still continue to use its own private cache.
  constructor: ({@root, @token, @errorHandler, @DEBUG, @help, noCache}) ->
    unless @root?
      throw new Error("No service root provided. This is required")
    if !HAS_PROTOCOL.test @root
      @root = DEFAULT_PROTOCOL + @root
    if !HAS_SUFFIX.test @root
      @root = @root + SUFFIX
    @root = @root.replace /ice$/, "ice/" # Ensure trailing slash.
    @errorHandler ?= DEFAULT_ERROR_HANDLER
    @help ?= 'no.help.available@dev.null'
    @useCache = not noCache # Peristent processes might not want to cache model, version, etc.

    @getFormat = (intended = 'json') =>
      return intended

  # Convenience method for making basic POST requests.
  # @param [String] path The endpoint to post to.
  # @param [Object<String, String>, Array<[String, String]>] data parameters to send (optional)
  # @return [Promise<Object>] A promise to yield a response object.
  post: (path, data) -> @makeRequest 'POST', path, data

  # Convenience method for making basic GET requests.
  # @param [String] path The endpoint to get from.
  # @param [Object<String, String>, Array<[String, String]>] data parameters to send (optional)
  # @return [Promise<Object>] A promise to yield a response object.
  get: (path, data) -> @makeRequest 'GET', path, data

  # The generalised method through which ALL requests pass when using
  # this class. You should not use this method; instead use one of the
  # specific methods on this class (such as Service#fetchModel, or Service#fetchVersion)
  # or one of the methods on the Query object.
  #
  # TL/DR: Don't. Finger weg.
  #
  # @param [String] method The HTTP method to use (one of GET, POST, PUT, DELETE).
  # @param [String] path The path fragment of the endpoint to use. The service's root
  #   will be prepended to obtain the full URI.
  # @param [Object,Array] data The parameters to send to the service.
  # @param [(data) ->] cb A function that will be called on the results when received.
  # @param [boolean] indiv A flag determinig whether to treat the results as a single block,
  #   or whether to yield individual results to the cb item by item. This only makes sense
  #   in the node.js context. Don't use this.
  #
  # All parameters are optional.
  #
  # @return [Promise<Object>] A promise to yield a response object.
  makeRequest: (method = 'GET', path = '', data = {}, cb = (->), indiv = false) ->
    if utils.isArray cb
      [cb, errBack] = cb
    if utils.isArray data
      data = utils.pairsToObj data

    errBack ?= @errorHandler
    data = utils.copy data
    dataType = @getFormat data.format

    # IE requires that we tunnel DELETE and PUT
    unless http.supports method
      [data.method, method] = [method, http.getMethod(method)]

    opts =
      data: data,
      dataType: dataType,
      success: cb,
      error: errBack,
      path: path,
      type: method

    if 'headers' of data
      opts.headers = utils.copy data.headers
      delete opts.data.headers

    if timeout = (data.timeout ? @timeout)
      opts.timeout = timeout
      delete data.timeout

    @authorise(opts).then (authed) => @doReq authed, indiv

  # TODO - when 14 is prevalent the fetchVersion can be removed.
  authorise: (req) -> @fetchVersion().then (version) =>
    opts = utils.copy req
    opts.headers ?= {}
    opts.url = @root + opts.path
    pathAdditions = []

    if version < 14
      if 'string' is typeof opts.data
        pathAdditions.push ['format', opts.dataType]
      else
        opts.data.format = opts.dataType

    if @token? and NEEDS_AUTH req.path, opts.data?.query
      if version >= 14
        opts.headers.Authorization = "Token #{ @token }"
      else if 'string' is typeof opts.data
        pathAdditions.push ['token', @token]
      else
        opts.data.token = @token

    if pathAdditions.length
      opts.url += '?' + to_query_string pathAdditions

    return opts

  # Get the results of using a list enrichment widget to calculate
  # statistics for a set of objects. An enrichment calculation
  # attempts to find related items that are particularly characteristic
  # of the items in this list.
  # @param [Object<String, String>] opts The parameters to pass to the calculation.
  # @option opts [String] list The name of the list to analyse.
  # @option opts [String] widget The name of the enrichment calculation to use.
  # @option opts [Number] maxp The maximum permissible p-value (optional, default = 0.05).
  # @option opts [String] correction The correction algorithm to use (default = Holm-Bonferroni).
  # @option opts [String] population The name of a list to use as a background
  #   population (optional).
  # @option opts [String] filter An extra value that some widget calculations accept.
  # @param [->] cb A function to call with the results when they have been received (optional).
  # @return [Promise<Array<Object>>] A promise to get results.
  enrichment: (opts, cb) => REQUIRES_VERSION @, 8, =>
    req = merge {maxp: 0.05, correction: 'Holm-Bonferroni'}, opts
    @get(ENRICHMENT_PATH, req)
      .then(get 'results')
      .nodeify cb

  # Search for items in the database by any term or facet.
  #
  # This method performs a wide-ranging free-text search (powered
  # by Lucene) for items in the database matching a given term. The data
  # returned is limited to a precalculated document of key-fields for
  # each object. To further explore the dataset, the user will
  # want to construct more sophisticated queries. See {Query}.
  #
  # The yielded result has a results property and a facets property.
  #
  # @param [Object] options A collection of parameters.
  # @param [(Array.<Object>, Object, Object) ->] An optional call-back function.
  # @option options [String] q The term to search by.
  # @option options [Object<String, String>] facets A set of facet constraints.
  # @return [Promise<Object>] A promise to search the database.
  search: (options = {}, cb = (->)) -> REQUIRES_VERSION @, 9, =>
    [cb, options] = [options, {}] if utils.isFunction options
    if typeof options is 'string'
      req = q: options
    else
      req = q: options.q
      for own k, v of options when k isnt 'q'
        req["facet_#{ k }"] = v

    withCB cb, @post(QUICKSEARCH_PATH, req)

  # Make a PathInfo object from a string
  #
  # Sugar for `service.fetchModel().then (m) -> m.makePath path, subclasses`
  #
  # @param [String] path The path string.
  # @param [Object<String, String>] subclasses The subclass info.
  # @param [Function<Error, PathInfo, Void>] cb An optional callback.
  # @return [Promise<PathInfo>] A promise to yield a PathInfo object.
  makePath: (path, subclasses = {}, cb = (->)) ->
    withCB cb, @fetchModel().then (m) -> m.makePath path, subclasses

  # Find out how many rows a given query would return when run.
  #
  # @param [Query|PathInfo|String|Object] The query to run. If it is not already instantiated
  #   as a Query object, it will be, so the JSON definition of a query can be used
  #   here. Alternatively a single path argument (as a PathInfo object or as a string) may be used,
  #   in which cases the count of all unique values for that path will be
  #   returned.
  # @param [(Number) ->] cb A callback that receives a number. Optional.
  # @return [Promise<Number>] A promise to yield a count.
  count: (q, cb = (->)) =>
    withCB cb, if not q
      error "Not enough arguments"
    else if q.toPathString?
      p = if q.isClass() then q.append('id') else q
      @pathValues(p, 'count')
    else if q.toXML?
      req = {query: q, format: 'jsoncount'}
      @post(QUERY_RESULTS_PATH, req).then(get 'count')
    else if typeof q is 'string'
      @fetchModel().then (m) =>
        try
          @count m.makePath q
        catch e # could be star, try as a query
          @query(select: [q]).then(@count)
    else
      @query(q).then(@count)

  # Retrieve a representation of a specific object.
  # @param [String] type The type of the object to find (eg: Gene)
  # @param [Number] id The internal DB id of the object.
  # @param [(obj) ->] A callback that receives an object. (optional).
  # @return [Promise<Object>] A promise to yield an object.
  findById: (type, id, cb) =>
    withCB cb, @query(from: type, select: ['**'], where: {id: id})
      .then(dejoin)
      .then(invoke 'records')
      .then(get 0)

  # Find all the objects in the database that match the search term.
  # @param [String] type The type of the object to find (eg: Gene)
  # @param [String] term A search term to use. This may use wild-cards and
  #   comma separated sub-terms. eg: "eve, zen, bib, r, H"
  # @param [(Array<Object>) ->] cb A callback that receives an Array of objects. (optional).
  # @return [Promise<Array<Object>>] A promise to yield an array of objects.
  lookup: (type, term, context, cb) ->
    if utils.isFunction context
      [context, cb] = [null, context]
    withCB cb, @query(from: type, select: ['**'], where: [[type, 'LOOKUP', term, context]])
      .then(dejoin)
      .then(invoke 'records')

  # Find the single object that matches the given term, or report an error if none is
  # found, or more than one is found.
  # @param [String] type The type of the object to find (eg: Gene)
  # @param [String] term A search term to use. This may use wild-cards and
  #   comma separated sub-terms. eg: "eve, zen, bib, r, H"
  # @param [(Array<Object>) ->] cb A callback that receives an Array of objects. (optional).
  # @return [Promise<Array<Object>>] A promise to yield an array of objects.
  find: (type, term, context, cb) ->
    if utils.isFunction context
      [context, cb] = [null, context]
    withCB cb, @lookup(type, term, context).then (found) ->
      if not found? or found.length is 0
        error "Nothing found"
      else if found.length > 1
        error "Multiple items found: #{ found.slice(0, 3) }..."
      else
        success found[0]

  # Retrieve information about the currently authenticated user.
  # @param [(User) ->] cb A callback the receives a User object.
  # @return [Promise<User>] A promise to yield a user.
  whoami: (cb) => REQUIRES_VERSION @, 9, =>
    withCB cb, @get(WHOAMI_PATH).then(get 'user').then((x) => new User(@, x))

  # Alias for {Service#whoami}
  fetchUser: (args...) => @whoami args...

  # Retrieve a list of values that a path can have.
  # This functionality is expected to be of use when developing auto-completion interfaces.
  # @see {Query#summarise}
  # @param [.toString|PathInfo] path The path to evaluate.
  # @param [Object<String, String>] typeConstraints The type constraints on this path.
  #   (only required if there are any. Default = {}).
  # @param [(Array<Object>|Number) ->] cb An optional callback.
  # @return [Promise<Array<Object>, Number>] A promise to return a list of objects with
  #   two properties ('count' and 'value').
  pathValues: (path, typeConstraints = {}, cb) => REQUIRES_VERSION @, 6, =>
    if typeof typeConstraints is 'string'
      wanted = typeConstraints
      typeConstraints = {}
    if utils.isFunction(typeConstraints)
      [typeConstraints, cb] = [cb, typeConstraints]

    wanted = 'results' unless wanted is 'count'

    _pathValues = (path) =>
      format = if wanted is 'count' then 'jsoncount' else 'json'
      req = {format, path: path.toString(), typeConstraints: JSON.stringify(path.subclasses)}
      @post(PATH_VALUES_PATH, req).then(get wanted)

    try
      withCB cb, @fetchModel().then(invoke 'makePath', path, (path.subclasses ? typeConstraints))
                   .then(_pathValues)
    catch e
      error e


  # Perform a request for results that accepts a parameter specifying the
  # page to fetch. Not intended for public consumption.
  #
  # @private
  # @param [Query|Object] q The query to request results for. If not a {Query}, the object
  #   will be lifted to one via {Service#query}
  # @param [String] The path to make this request to.
  # @param [Object] page An object specifying the page (optional).
  # @option page [Number] start The index of the first result to
  #   retrieve (default = 0).
  # @option page [Number] size The maximum number of results to
  #   retrieve (default = null, ie. 'all').
  # @param [String] format The format to request results in (eg. 'json').
  # @param [->] cb A call-back to which results will be yielded. (optional).
  #
  # @return [Promise<Array<?>>] A promise to yield results.
  doPagedRequest: (q, path, page = {}, format, cb = (->)) ->
    if q.toXML?
      [cb, page] = [page, {}] if utils.isFunction page
      req = merge page, query: q, format: format
      # TODO: Is there a good reason to want access to the envelope? How to expose...
      withCB cb, @post(path, req).then get 'results'
    else
      @query(q).then((query) => @doPagedRequest(query, path, page, format, cb))

  # Get a page of results in jsontable format.
  #
  # @param [Query|Object] q The query to request results for. If not a {Query}, the object
  #   will be lifted to one via {Service#query}
  # @param [Object] page An object specifying the page (optional).
  # @option page [Number] start The index of the first result to
  #   retrieve (default = 0).
  # @option page [Number] size The maximum number of results to
  #   retrieve (default = null, ie. 'all').
  # @param [->] cb A call-back to which results will be yielded. (optional).
  #
  # @return [Promise<Array<?>>] A promise to yield results.
  table: (q, page, cb) => @doPagedRequest(q, QUERY_RESULTS_PATH, page, 'jsontable', cb)

  # Get a page of results in jsonobject format.
  #
  # @param [Query|Object] q The query to request results for. If not a {Query}, the object
  #   will be lifted to one via {Service#query}
  # @param [Object] page An object specifying the page (optional).
  # @option page [Number] start The index of the first result to
  #   retrieve (default = 0).
  # @option page [Number] size The maximum number of results to
  #   retrieve (default = null, ie. 'all').
  # @param [->] cb A call-back to which results will be yielded. (optional).
  #
  # @return [Promise<Array<Object>>] A promise to yield results.
  records: (q, page, cb) => @doPagedRequest(q, QUERY_RESULTS_PATH, page, 'jsonobjects', cb)

  # Get a page of results in json format.
  #
  # @param [Query|Object] q The query to request results for. If not a {Query}, the object
  #   will be lifted to one via {Service#query}
  # @param [Object] page An object specifying the page (optional).
  # @option page [Number] start The index of the first result to
  #   retrieve (default = 0).
  # @option page [Number] size The maximum number of results to
  #   retrieve (default = null, ie. 'all').
  # @param [->] cb A call-back to which results will be yielded. (optional).
  #
  # @return [Promise<Array<Array<Object>>] A promise to yield results.
  rows: (q, page, cb) => @doPagedRequest(q, QUERY_RESULTS_PATH, page, 'json', cb)

  # Get a page of values.
  #
  # @param [Query|Object|PathInfo|String] q The query to request results for.
  #        If a PathInfo object or a String, then the pathValues method
  #        will be run instead (backward compatibility). Otherwise the first
  #        argument will be treated as a query as per the {Service#rows} method.
  # @param [Object] opts Either a page, or options for pathValues.
  # @param [->] cb A call-back to which results will be yielded. (optional).
  #
  # @return [Promise<<Array<Object>] A promise to yield results.
  values: (q, opts, cb) =>
    if utils.isFunction opts
      [cb, opts] = [opts, cb]

    resp = if not q?
      error "No query term supplied"
    else if q.descriptors? or typeof q is 'string'
      @pathValues(q, opts).then(map get 'value')
    else if q.toXML?
      if q.views.length isnt 1
        error "Expected one column, got #{ q.views.length }"
      else
        @rows(q, opts).then(map get 0)
    else
      @query(q).then (query) => @values query, opts

    withCB cb, resp

  # Get a page of results suitable for building the cells in a table.
  #
  # @param [Query|Object] q The query to request results for. If not a {Query}, the object
  #   will be lifted to one via {Service#query}
  # @param [Object] page An object specifying the page (optional).
  # @option page [Number] start The index of the first result to
  #   retrieve (default = 0).
  # @option page [Number] size The maximum number of results to
  #   retrieve (default = null, ie. 'all').
  # @param [->] cb A call-back to which results will be yielded. (optional).
  #
  # @return [Promise<Array<Array<Object>>] A promise to yield results.
  tableRows: (q, page, cb) => @doPagedRequest(q, TABLE_ROW_PATH, page, 'json', cb)

  # Get the templates this user currently has access to.
  #
  # @param [(Error?, Array<Object>) ->] cb A callback (optional).
  # @return [Promise<Object>] A promise to yield a mapping of templates.
  fetchTemplates: (cb) => withCB cb, @get(TEMPLATES_PATH).then get 'templates'

  # Get the lists this user currently has access to.
  #
  # @param [(Array<List>) ->] cb A callback (optional).
  # @return [Promise<Array<List>>] A promise to yield an array of {List} objects.
  fetchLists: (cb) => @findLists '', cb

  # Get the lists this user currently has access to which match the given name.
  #
  # @param [String] name The name the lists we want to find must have (may include wildcards).
  #   (Optional - default = '', ie. all lists).
  # @param [(Array<List>) ->] cb A callback (optional).
  # @return [Promise<Array<List>>] A promise to yield an array of {List} objects.
  findLists: (name = '', cb = (->)) => @fetchVersion().then (v) =>
    withCB cb, if name and v < 13
      error "Finding lists by name on the server requires version 13. This is only #{ v }"
    else
      fn = (ls) => (new List(data, @) for data in ls)
      @get(LISTS_PATH, {name}).then(get 'lists').then(fn)

  # Get a list by name.
  #
  # @param [String] name The exact name of the list.
  # @param [->] cb A callback function (optional).
  # @return [Promise<List>] A promise to yield a {List}.
  fetchList: (name, cb) => @fetchVersion().then (v) =>
    withCB cb, if v < 13
      @findLists().then(getListFinder(name))
    else
      @findLists(name).then(get 0)

  # Get the lists that contain the given object.
  #
  # @param [Object] opts The options that specify which object.
  # @option opts [String] publicId The stable identifier of the object (eg.
  #   for a Gene, the symbol).
  # @option opts [String] extraValue A disambiguating value (eg. for a
  #   Gene, the name of the Organism it belongs to).
  # @option opts [#toString] id If known, an object may be referenced
  #   by its internal DB id instead. These are NOT stable between releases
  #   of the webapp, so should never be stored.
  # @param [->] cb A callback function (Optional).
  # @return [Promise<Array<List>>] A promise to yield an array of {List} objects.
  fetchListsContaining: (opts, cb) =>
    fn = (xs) => (new List(x, @) for x in xs)
    withCB cb, @get(WITH_OBJ_PATH, opts).then(get 'lists').then(fn)

  # Combine two or more lists using the given operation.
  #
  # @param [String] operation One of ['merge', 'intersect', 'diff'].
  # @param [Object] options The options that describe what to combine.
  # @option options [String] name The name of the new list.
  # @option options [String] description The description of the new list.
  #   (optional - defaults to "operation of listA, listB")
  # @option options [Array<String>] lists The lists to combine.
  # @option options [Array<String>] tags A set of tags to apply to the new list (optional).
  # @param [(List) ->] cb A callback function. (optional).
  # @return [Promise<List>] A promise to yield a {List} object.
  combineLists: (operation, options, cb) ->
    {name, lists, tags, description} = merge {lists: [], tags: []}, options
    req = {name, description}
    req.description ?= "#{ operation } of #{ lists.join(', ') }"
    req.tags = tags.join(';')
    req.lists = lists.join(';')
    withCB cb, @get(LIST_OPERATION_PATHS[operation], req).then(LIST_PIPE @)

  # Combine two or more lists through a union operation.
  #
  # also available as {Service#union}.
  #
  # @param [Object] options The options that describe what to combine.
  # @option options [String] name The name of the new list.
  # @option options [String] description The description of the new list.
  #   (optional - defaults to "operation of listA, listB")
  # @option options [Array<String>] lists The lists to combine.
  # @option options [Array<String>] tags A set of tags to apply to the new list (optional).
  # @param [(List) ->] cb A callback function. (optional).
  # @return [Promise<List>] A promise to yield a {List} object.
  merge: -> @combineLists 'union', arguments...

  # Combine two or more lists through an intersection operation.
  #
  # @param [Object] options The options that describe what to combine.
  # @option options [String] name The name of the new list.
  # @option options [String] description The description of the new list.
  #   (optional - defaults to "operation of listA, listB")
  # @option options [Array<String>] lists The lists to combine.
  # @option options [Array<String>] tags A set of tags to apply to the new list (optional).
  # @param [(List) ->] cb A callback function. (optional).
  # @return [Promise<List>] A promise to yield a {List} object.
  intersect: -> @combineLists 'intersection', arguments...

  # Combine two more lists through a symmetric difference opertation.
  #
  # @param [Object] options The options that describe what to combine.
  # @option options [String] name The name of the new list.
  # @option options [String] description The description of the new list.
  #   (optional - defaults to "operation of listA, listB")
  # @option options [Array<String>] lists The lists to combine.
  # @option options [Array<String>] tags A set of tags to apply to the new list (optional).
  # @param [(List) ->] cb A callback function. (optional).
  # @return [Promise<List>] A promise to yield a {List} object.
  diff: -> @combineLists 'difference', arguments...

  # Create a new list from the complement of two groups of lists. The
  # complement is often what is meant by the concept of subtraction, in that the
  # result of this operation will always be a proper subset of the union
  # of the references.
  #
  # @param [Object] options The parameters to this option.
  # @option options [String] name The name for the new list. (optional,
  #   defaults to "The reverse complement of B in A")
  # @option options [String] description The description of the new list (optional,
  #   defailts to "The reverse complement of B in A")
  # @option options [String|Array<String>] tags The tags the new list should have.
  # @option options [String|List|Array<String|List>] from The lists that serve
  #   as the left hand side in the complement, ie. the union of lists we will subtract
  #   items from.
  # @option options [String|List|Array<String|List>] exclude The lists that serve
  #   as the right hand side in the complement, ie. the union of lists we will subtract
  #   from the reference lists.
  # @param cb [(List) ->] cb An optional callback.
  # @return [Promise<List>] A promise to yield a {List}.
  complement: (options = {}, cb = ->) =>
    {from, exclude, name, description, tags} = options
    defaultDesc = ->
      "Relative complement of #{ lists.join ' and ' } in #{ references.join ' and '}"
    references = TO_NAMES from
    lists = TO_NAMES exclude
    name ?= defaultDesc()
    description ?= defaultDesc()
    tags ?= []
    req = {name, description, tags, lists, references}
    withCB cb, @post(SUBTRACT_PATH, req).then(LIST_PIPE @)

  # The following methods fetch resources that can be considered
  # stable - they are not expected to change between releases of
  # the web-service. Long running processes should take care either to
  # set 'noCache' on the service, or to regularly call Service.flush().

  # Fetch the list widgets that are available from this service.
  # @return [Promise<Array<Object>>] A promise to yield a list of widgets.
  fetchWidgets: (cb) => REQUIRES_VERSION @, 8, =>
    _get_or_fetch.call @, 'widgets', WIDGETS, WIDGETS_PATH, 'widgets', cb

  toMapByName = utils.omap (w) -> [w.name, w]

  fetchWidgetMap: (cb) => REQUIRES_VERSION @, 8, =>
    withCB cb, (@__wmap__ ?= @fetchWidgets().then toMapByName)

  # Fetch the description of the data model for this service.
  # @return [Promise<Model>] A promise to yield metadata about this service.
  fetchModel: (cb) =>
    _get_or_fetch.call(@, 'model', MODELS, MODEL_PATH, 'model')
      .then(Model.load)
      .then(set service: @)
      .nodeify(cb)

  # Fetch the configured summary-fields.
  # The summary fields describe which fields should be used to summarise each class.
  # @return [Promise<Object<String, Array<String>>>] A promise to yield a mapping
  #   from class-name to a list of paths.
  fetchSummaryFields: (cb) =>
    _get_or_fetch.call @, 'summaryFields', SUMMARY_FIELDS, SUMMARYFIELDS_PATH, 'classes', cb

  # Fetch the number that describes the web-service capabilities.
  # @return [Promise<Number>] A promise to yield a version number.
  fetchVersion: (cb) =>
    _get_or_fetch.call @, 'version', VERSIONS, VERSION_PATH, 'version', cb

  fetchClassKeys: (cb) =>
    _get_or_fetch.call @, 'classkeys', CLASSKEYS, CLASSKEY_PATH, 'classes', cb

  fetchRelease: (cb) =>
    _get_or_fetch.call @, 'release', RELEASES, RELEASE_PATH, 'version', cb

  # Promise to make a new Query.
  #
  # @param [Object] options The JSON representation of the query. See {Query#constructor}
  #   for more information on the structure of these options.
  # @param [(Error?, Query) ->] cb An optional callback to be called when the query is made.
  # @return [Promise<Query>] A promise to yield a new {Query}.
  query: (options, cb) =>
    buildQuery = ([model, summaryFields]) => new Query options, @, {model, summaryFields}
    withCB cb, Promise.all(@fetchModel(), @fetchSummaryFields()).then(buildQuery)

  loadQ = (service, name) -> (q) ->
    return error "No query found called #{ name }" unless q
    service.query q

  checkNameParam = (name) ->
    if name
      if ('string' is typeof name) then success() else error "Name must be a string"
    else
      error "Name not provided"

  # Load a saved query by name.
  #
  # @param [String] name The name of the query.
  # @param [(Error?, Query) ->] cb An optional node-style callback.
  # @return [Promise<Query>] A promise to yield a query.
  savedQuery: (name, cb) => REQUIRES_VERSION @, 16, => checkNameParam(name).then =>
    withCB cb, @get('user/queries', filter: name).then((r) -> r.queries[name]).then loadQ @, name

  # Load a template query by name.
  #
  # @param [String] name The name of the template
  # @param [(Error?, Query) ->] cb An optional node-style callback.
  # @return [Promise<Query>] A promise to return a query.
  templateQuery: (name, cb) => checkNameParam(name).then =>
    withCB cb, @fetchTemplates().then(get name).then(set 'type', 'TEMPLATE').then loadQ @, name

  # Perform operations on a user's preferences.
  #
  # @private
  # @param [String] method The HTTP method to call.
  # @param [Object] data The parameters for this request.
  # @return [Promise<Object>] A promise to yield the user's preferences
  #   following the update.
  manageUserPreferences: (method, data, cb) -> REQUIRES_VERSION @, 11, =>
    withCB cb, @makeRequest(method, PREF_PATH, data).then(get 'preferences')

  # Submit an ID resolution job.
  # @param [Object] opts The parameters to the id resolution service.
  # @option opts [Array<String>] identifiers The identifiers you want to resolve.
  # @option opts [String] type The type of objects these identifiers refer to.
  # @option opts [String] extra Extra values that can be used to disambiguate values (optional).
  # @option opts [boolean] caseSensitive Whether these identifiers should be treated
  #   as case-sensitive. (optional).
  # @option opts [boolean] wildCards Whether wild-cards should be allowed in these
  #   identifiers. (optional).
  # @param [->] cb An optional callback.
  # @return [Promise<IDResolutionJob>] A promise to yield a job id.
  resolveIds: (opts, cb) => REQUIRES_VERSION @, 10, =>
    req =
      type: 'POST'
      url: @root + ID_RESOLUTION_PATH
      contentType: 'application/json'
      data: JSON.stringify(opts)
      dataType: 'json'
    withCB cb, @doReq(req).then(get 'uid').then(IDResolutionJob.create @)

  # Create a new list through the identifier upload service.
  #
  # This service takes a source of identifiers and attempts to resolve them automatically
  # and create a new list for the results. If you require more fine-grained control
  # over this functionality then see [Service#resolveIds].
  #
  # @param [Object] opts The options for this list upload.
  # @option opts [String] name The name for this list (required).
  # @option opts [String] type The type of objects (eg. Gene) these are identifiers of (required).
  # @option opts [String] description A description for the new list (optional).
  # @option opts [String] extraValue A disambiguating value (optional).
  # @option opts [Array<String>] tags A list of tags to apply to the new list (optional).
  # @param [Array<String>|String] ids The identifiers to resolve.
  # @param [(Error, List) -> Any] cb A function that receives a {List}.
  # @return [Promise<List>] A promise to yield a {List}.
  createList: (opts = {}, ids = '', cb = ->) =>
    adjust = (x) => merge x, {@token, tags: (opts.tags or [])}
    req =
      data: if utils.isArray(ids) then ids.map((x) -> "\"#{ x }\"").join("\n") else ids
      dataType: 'json'
      url: "#{ @root }lists?#{to_query_string adjust opts}"
      type: 'POST'
      contentType: 'text/plain'

    withCB cb, @doReq(req).then(LIST_PIPE @)

  getNewUserToken = (resp) -> resp.user.temporaryToken

  # Return a new service with the same root url as this one, but connected as a different
  # user.
  # @param [String] token The token for the user to connect as.
  # @return [Service] A new connection to a service.
  connectAs: (token) => Service.connect merge @, {token, noCache: not @useCache}

  # Create a new user at the current service.
  #
  # @param [String] name The name of the new user. Used a login.
  # @param [String] password The cleartext version of the user's password.
  # @param [(Error, Service) -> Any] cb An optional callback.
  # @return [Promise<Service>] A promise to yield a new service for use with the new user.
  register: (name, password, cb) -> REQUIRES_VERSION @, 9, =>
    withCB cb, @post('users', {name, password}).then(getNewUserToken).then(@connectAs)

  FIVE_MIN = 5 * 60

  # Promise to get a deregistration token.
  #
  # To provide some security to the account deregistration process account deactivation
  # is a two-stage process - first a deregistration token must be acquired, and only
  # then can a request to delete a user be made.
  #
  # @param [Number] The number of seconds the token should be valid (default = 5 minutes).
  # @param [(Error, String) -> Any] An optional callback.
  # @return [Promise<String>] A promise to return a token which can be used to delete an account.
  getDeregistrationToken: (validity = FIVE_MIN, cb) -> REQUIRES_VERSION @, 16, =>
    promise = if @token?
      @post('user/deregistration', {validity}).then get 'token'
    else
      error "Not registered"
    withCB cb, promise

  # Return a promise to delete a user account, and retrieve all of its data.
  #
  # Before the user this service is connected to can be deleted, a deregistration token
  # must be obtained via a call to 'getDeregistrationToken'.
  #
  # @param [String] The deregistration token to activate.
  # @param [(Error, String) -> Any] An optional callback
  # @return [Promise<String>] A promise to yield all the userdata for an account as XML.
  deregister: (token, cb) -> REQUIRES_VERSION @, 16, =>
    withCB cb, @makeRequest('DELETE', 'user', deregistrationToken: token, format: 'xml')

  # Promise to return a service with the same root as this one, but associated with
  # a different user account - the one specified by the login details.
  # @param [(Error, Service) -> Any] cb An optional callback
  # @return [Promise<Service>] A promise to yield a service.
  login: (name, password, cb) -> REQUIRES_VERSION @, 9, =>
    headers = {'Authorization': "Basic " + base64.encode("#{ name }:#{ password }")}
    withCB cb, @logout().then((service) -> service.get('user/token', {headers}))
                        .then(get 'token')
                        .then(@connectAs)

  # Promise to return a service with the same root as this one, but not associated with any
  # user account. Attempts to use the yielded service to make list requests and
  # other requests that require authenticated access will fail.
  # @param [(Error, Service) -> Any] cb An optional callback
  # @return [Promise<Service>] A promise to yield a service.
  logout: (cb) -> withCB cb, success @connectAs()

# Methods for processing items individually.

# Process the results of a query row by row.
#
# @param [Query] q The query to run.
# @param [Object] page The page of results to return.
# @option page [Number] start The index of the first row to
#   return (optional; default = 0)
# @option page [Number] size The maximum number of results to
#   return (optional; default = null, ie. all)
# @param [->] doThis A callback for each row (optional).
# @param [->] onErr A callback to handle errors (optional).
# @param [->] onEnd A callback to be called when all rows have
#   been received (optional).
# @return [Promise<BufferedReader<Array<Object>>>] a promise to
#   yield an iterator over the rows.
Service::rowByRow = (q, args...) ->
  f = http.iterReq 'POST', QUERY_RESULTS_PATH, 'json'
  if q.toXML?
    f.apply this, arguments
  else
    @query(q).then (query) => @rowByRow query, args...
    
# Alias for {Service#rowByRow}
Service::eachRow = Service::rowByRow

# Process the results of a query item by item.
#
# @param [Query] q The query to run.
# @param [Object] page The page of results to return. It is best
#   not to try and page object based results unless for batching
#   reasons.
# @option page [Number] start The index of the first row to
#   return (optional; default = 0)
# @option page [Number] size The maximum number of results to
#   return (optional; default = null, ie. all)
# @param [->] doThis A callback for each row (optional).
# @param [->] onErr A callback to handle errors (optional).
# @param [->] onEnd A callback to be called when all rows have
#   been received (optional).
# @return [Promise<BufferedReader<Object>>] a promise to
#   yield an iterator over the results.
Service::recordByRecord = (q, args...) ->
  f = http.iterReq 'POST', QUERY_RESULTS_PATH, 'jsonobjects'
  if q.toXML?
    f.apply this, arguments
  else
    @query(q).then (query) => @recordByRecord query, args...
  
  
# Alias for {Service#recordByRecord}
Service::eachRecord = Service::recordByRecord

# Alias for {Service#merge}
Service::union = Service::merge

# Alias for {Service#diff}
Service::difference = Service::diff
Service::symmetricDifference = Service::diff

# Alias for {Service#complement}
Service::relativeComplement = Service::complement
Service::subtract = Service::complement

# Static method to flush the cached
# models, versions and summary-field informations.
#
# This should be used if running in a persistent process and this data is
# at risk of getting stale.
Service.flushCaches = () ->
  MODELS = {}
  VERSIONS = {}
  RELEASES = {}
  CLASSKEYS = {}
  SUMMARY_FIELDS = {}
  WIDGETS = {}

# Static method for instantiation. Allows us to provide
# alternate implementations in the future, and pass this function
# around when needed.
Service.connect = (opts) ->
  throw new Error "Invalid options provided: #{ JSON.stringify opts }" unless opts?.root?
  new Service opts

# This module serves as a main entry point, so re-export
# the public parts of the API.
intermine.Service = Service
intermine.Model = Model
intermine.Query = Query
intermine.utils = utils
intermine.imjs = version
