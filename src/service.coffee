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
IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

# Import from the appropriate place depending on whether
# if we are in node.js or in the browser.
if IS_NODE
  {_}            = require('underscore')
  {Deferred}     = $ = require('underscore.deferred')
  {Model}        = require('./model')
  {Query}        = require('./query')
  {List}         = require('./lists')
  {User}         = require('./user')
  {IDResolutionJob} = require('./id-resolution-job')
  funcutils      = require('./util')
  to_query_string    = require('querystring').stringify
  http           = require('./http')
  intermine = exports
else
  {_, jQuery, intermine} = __root__
  {Deferred} = $ = jQuery
  to_query_string = (obj) -> jQuery.param(obj, true) # traditional serialization.
  {Model, Query, List, User, IDResolutionJob, funcutils, http} = intermine

{pairsToObj, omap, get, set, invoke, success, error, REQUIRES_VERSION, dejoin} = funcutils

# Set up all the private closed over variables
# that the service will want, but don't need
# exposing to the outside world.

# Cache resources that are meant to be stable.
# Stable resources do not change between releases
# of a service.
VERSIONS = {}
MODELS = {}
SUMMARY_FIELDS = {}
WIDGETS = {}

# If the user doesn't add one on their
# url, assume HTTP.
DEFAULT_PROTOCOL = "http://"

# A list of endpoints exposed by the service.
VERSION_PATH = "version"
TEMPLATES_PATH = "templates"
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

# The identity function f x = x
IDENTITY = (x) -> x

# Pattern for detecting if URI has a protocol
HAS_PROTOCOL = /^https?:\/\//i

# Pattern for detecting if the URI has the necessary service suffix.
HAS_SUFFIX = /service\/?$/i

# The suffix all service URIs must end in.
SUFFIX = "/service/"

# BY DEFAULT, LOG ERRORS TO THE CONSOLE.
DEFAULT_ERROR_HANDLER = (e) ->
  if IS_NODE and e.stack?
    console.error e.stack
  else
    args = if (e?.stack) then [e.stack] else arguments
    (console.error || console.log)?.apply(console, args) if console?

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
  prop = @[propName] ?= if (@useCache and value = store[@root])
    success(value)
  else
    @get(path).pipe(get key).done (x) => store[@root] = x
  prop.done cb

# A private helper that produces a function that will read
# through an array of Lists, and find the first one with the
# given name. The returned function returns a promise to find
# the given list, and will be rejected if no list of that name
# can be found.
# @param [String] name The name of the list to find.
# @return [([List]) -> Deferred.<List>] A function from an array of
#   List objects to a promise to return a List.
getListFinder = (name) -> (lists) -> Deferred ->
  if list = (_.find lists, (l) -> l.name is name)
    @resolve list
  else
    @reject """List "#{ name }" not found among: #{ lists.map get 'name' }"""

LIST_PIPE = (service, prop = 'listName') -> _.compose service.fetchList, get prop
TO_NAMES = (xs = []) -> (x.name ? x for x in (if _.isArray(xs) then xs else [xs]))

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
    @root = @root.replace /ice$/, "ice/"
    @errorHandler ?= DEFAULT_ERROR_HANDLER
    @help ?= 'no.help.available@dev.null'
    @useCache = !noCache # Peristent processes might not want to cache model, version, etc.
    loc = if IS_NODE then '' else location.protocol + '//' + location.host

    @getFormat = (intended = 'json') =>
      unless /jsonp/.test intended # already JSON-P
        unless IS_NODE || jQuery.support.cors # not necessary
          unless loc.substring(0, @root.length) is @root # Not X-Domain
            return intended.replace 'json', 'jsonp'

      return intended

  # Convenience method for making basic POST requests.
  # @param [String] path The endpoint to post to.
  # @param [Object<String, String>, Array<[String, String]>] data parameters to send (optional)
  # @return [Promise<Object>] A promise to yield a response object.
  post: (path, data = {}) -> @makeRequest 'POST', path, data

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
    if _.isArray cb
      [cb, errBack] = cb
    if _.isArray data
      data = pairsToObj data

    url = @root + path
    errBack ?= @errorHandler
    data.token = @token if @token
    data.format = @getFormat(data.format)

    if /jsonp/.test data.format
      # tunnel the true method
      data.method = method
      method = 'GET'
      url += '?callback=?'

    dataType = if /json/.test(data.format) then 'json' else 'text'

    # IE requires that we tunnel DELETE and PUT
    unless http.supports method
      [data.method, method] = [method, http.getMethod(method)]

    if method is 'DELETE'
      # grumble grumble struts grumble grumble...
      # (struts won't read query data from the request body
      # of DELETE requests).
      url += '?' + to_query_string data

    opts =
      data: data,
      dataType: dataType,
      success: cb,
      error: errBack,
      url: url,
      type: method

    return @doReq(opts, indiv)


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
    @get(ENRICHMENT_PATH, _.defaults {}, opts, maxp: 0.05, correction: 'Holm-Bonferroni')
      .pipe(get 'results')
      .done(cb)

  # Search for items in the database by any term or facet.
  #
  # This method performs a wide-ranging free-text search (powered
  # by Lucene) for items in the database matching a given term. The data
  # returned is limited to a precalculated document of key-fields for
  # each object. To further explore the dataset, the user will
  # want to construct more sophisticated queries. See {Query}.
  #
  # @param [Object] options A collection of parameters.
  # @param [(Array.<Object>, Object, Object) ->] An optional call-back function.
  # @option options [String] q The term to search by.
  # @option options [Object<String, String>] facets A set of facet constraints.
  # @return [Promise<Array, Object, Object>] A promise to search the database.
  search: (options = {}, cb = (->)) -> REQUIRES_VERSION @, 9, =>
    [cb, options] = [options, {}] if _.isFunction options
    options = {q: options} if _.isString options
    req = _.defaults {}, options, {q: ''}
    delete req.facets # bad, but underscore 1.4.2 isn't common yet, so we can't use omit.
    if options.facets
      for k, v of options.facets
        req["facet_#{ k }"] = v
    parse = (response) -> success response.results, response.facets
    @post(QUICKSEARCH_PATH, req).pipe(parse).done(cb)

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
    if not q
      error "Not enough arguments"
    else if q.toPathString?
      p = if q.isClass() then q.append('id') else q
      @pathValues(p, 'count').done(cb)
    else if q.toXML?
      req = {query: q.toXML(), format: 'jsoncount'}
      @post(QUERY_RESULTS_PATH, req).pipe(get 'count').done(cb)
    else if _.isString q
      @fetchModel().pipe(invoke 'makePath', q.replace(/\.\*$/, '.id')).pipe(@count).done(cb)
    else
      @query(q).pipe(@count).done(cb)

  # Retrieve a representation of a specific object.
  # @param [String] type The type of the object to find (eg: Gene)
  # @param [Number] id The internal DB id of the object.
  # @param [(obj) ->] A callback that receives an object. (optional).
  # @return [Promise<Object>] A promise to yield an object.
  findById: (type, id, cb) =>
    @query(from: type, select: ['**'], where: {id: id})
      .pipe(dejoin)
      .pipe(invoke 'records')
      .pipe(get 0)
      .done(cb)

  # Find all the objects in the database that match the search term.
  # @param [String] type The type of the object to find (eg: Gene)
  # @param [String] term A search term to use. This may use wild-cards and
  #   comma separated sub-terms. eg: "eve, zen, bib, r, H"
  # @param [(Array<Object>) ->] cb A callback that receives an Array of objects. (optional).
  # @return [Promise<Array<Object>>] A promise to yield an array of objects.
  # TODO: add support for extra-values
  find: (type, term, cb) ->
    @query(from: type, select: ['**'], where: [[type, 'LOOKUP', term]])
      .pipe(dejoin)
      .pipe(invoke 'records')
      .done(cb)

  # Retrieve information about the currently authenticated user.
  # @param [(User) ->] cb A callback the receives a User object.
  # @return [Promise<User>] A promise to yield a user.
  whoami: (cb) => REQUIRES_VERSION @, 9, =>
    @get(WHOAMI_PATH).pipe(get 'user').pipe((x) => new User(@, x)).done(cb)

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
  pathValues: (path, typeConstraints = {}, cb = (->)) => REQUIRES_VERSION @, 6, =>
    if _.isString(typeConstraints)
      wanted = typeConstraints
      typeConstraints = {}

    wanted = 'results' unless wanted is 'count'

    _pathValues = (path) =>
      format = if wanted is 'count' then 'jsoncount' else 'json'
      req = {format, path: path.toString(), typeConstraints: JSON.stringify(path.subclasses)}
      @post(PATH_VALUES_PATH, req).pipe(get wanted)

    try
      @fetchModel().pipe(invoke 'makePath', path, (path.subclasses || typeConstraints))
                   .pipe(_pathValues)
                   .done(cb)
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
      [cb, page] = [page, {}] if _.isFunction page
      req = _.defaults {}, {query: q.toXML(), format: format}, page
      @post(path, req).pipe((resp) -> success(resp.results, resp)).done(cb)
    else
      @query(q).pipe((query) => @doPagedRequest(query, path, page, format, cb))

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
  values: (q, opts, cb = (->)) =>
    if not q?
      error "No query term supplied"
    else if q.descriptors? or _.isString q
      @pathValues(q, opts, cb)
    else
      @query(q).then (query) => # Lift to query, check and then run.
        if query.views.length isnt 1
          error "Expected one column, got #{ q.views.length }"
        else
          @rows(query, opts).then(invoke 'map', get 0).done(cb)

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
  # @param [(Array<Object>) ->] cb A callback (optional).
  # @return [Promise<Array<Object>>] A promise to yield an array of templates.
  fetchTemplates: (cb) => @get(TEMPLATES_PATH).pipe(get 'templates').done(cb)

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
  findLists: (name = '', cb = (->)) => @fetchVersion().pipe (v) =>
    if name and v < 13
      error "Finding lists by name on the server requires version 13. This is only #{ v }"
    else
      fn = (ls) => (new List(data, @) for data in ls)
      @get(LISTS_PATH, {name}).pipe(get 'lists').pipe(fn).done(cb)

  # Get a list by name.
  #
  # @param [String] name The exact name of the list.
  # @param [->] cb A callback function (optional).
  # @return [Promise<List>] A promise to yield a {List}.
  fetchList: (name, cb) => @fetchVersion().pipe (v) =>
    if v < 13
      @findLists().pipe(getListFinder(name)).done(cb)
    else
      @findLists(name).pipe(get 0).done(cb)

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
    @get(WITH_OBJ_PATH, opts).pipe(get 'lists').pipe(fn).done(cb)

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
    req = _.pick options, 'name', 'description'
    req.description ?= "#{ operation } of #{ options.lists.join(', ') }"
    req.tags = (options.tags or []).join(';')
    req.lists = (options.lists or []).join(';')
    @get(LIST_OPERATION_PATHS[operation], req).pipe(LIST_PIPE @).done(cb)

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
    @post(SUBTRACT_PATH, req).pipe(LIST_PIPE @).done(cb)

  # The following methods fetch resources that can be considered
  # stable - they are not expected to change between releases of
  # the web-service. Long running processes should take care either to
  # set 'noCache' on the service, or to regularly call Service.flush().

  # Fetch the list widgets that are available from this service.
  # @return [Promise<Array<Object>>] A promise to yield a list of widgets.
  fetchWidgets: (cb) => REQUIRES_VERSION @, 8, =>
    _get_or_fetch.call @, 'widgets', WIDGETS, WIDGETS_PATH, 'widgets', cb


  toMapByName = omap (w) -> [w.name, w]

  fetchWidgetMap: (cb) => REQUIRES_VERSION @, 8, =>
    (@__wmap__ ?= @fetchWidgets().then(toMapByName)).done(cb)

  # Fetch the description of the data model for this service.
  # @return [Promise<Model>] A promise to yield metadata about this service.
  fetchModel: (cb) ->
    _get_or_fetch.call(@, 'model', MODELS, MODEL_PATH, 'model')
      .pipe(Model.load)
      .pipe(set service: @)
      .done(cb)

  # Fetch the configured summary-fields.
  # The summary fields describe which fields should be used to summarise each class.
  # @return [Promise<Object<String, Array<String>>>] A promise to yield a mapping
  #   from class-name to a list of paths.
  fetchSummaryFields: (cb) ->
    _get_or_fetch.call @, 'summaryFields', SUMMARY_FIELDS, SUMMARYFIELDS_PATH, 'classes', cb

  # Fetch the number that describes the web-service capabilities.
  # @return [Promise<Number>] A promise to yield a version number.
  fetchVersion: (cb) ->
    _get_or_fetch.call @, 'version', VERSIONS, VERSION_PATH, 'version', cb

  # Promise to make a new Query.
  #
  # @param [Object] options The JSON representation of the query. See {Query#constructor}
  #   for more information on the structure of these options.
  # @param [(Query) ->] cb An optional callback to be called when the query is made.
  # @return [Promise<Query>] A promise to yield a new {Query}.
  query: (options, cb) => $.when(@fetchModel(), @fetchSummaryFields()).pipe (m, sfs) =>
    args = _.extend {}, options, {model: m, summaryFields: sfs}
    service = @
    Deferred ->
      @fail(service.errorHandler)
      @done(cb)
      try # The whole point of this is to catch errors.
        @resolve new Query(args, service)
      catch e
        @reject e

  # Perform operations on a user's preferences.
  #
  # @private
  # @param [String] method The HTTP method to call.
  # @param [Object] data The parameters for this request.
  # @return [Promise<Object>] A promise to yield the user's preferences
  #   following the update.
  manageUserPreferences: (method, data) -> REQUIRES_VERSION @, 11, =>
    @makeRequest(method, PREF_PATH, data).pipe(get 'preferences')

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
      url: @root + 'ids'
      contentType: 'application/json'
      data: JSON.stringify(opts)
      dataType: 'json'
    @doReq(req).pipe(get 'uid').pipe(IDResolutionJob.create @).done(cb)

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
  # @param [(List) ->] cb A function that receives a {List}.
  # @return [Promise<List>] A promise to yield a {List}.
  createList: (opts = {}, ids = '', cb = ->) =>
    adjust = (x) => _.defaults {@token, tags: (opts.tags or [])}, x
    req =
      data: if _.isArray(ids) then ids.map((x) -> "\"#{ x }\"").join("\n") else ids
      dataType: 'json'
      url: "#{ @root }lists?#{to_query_string adjust opts}"
      type: 'POST'
      contentType: 'text/plain'

    @doReq(req).pipe(LIST_PIPE @).done(cb)

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
    @query(arguments[0]).then (query) => @rowByRow query, args...
    
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
    @query(arguments[0]).then (query) => @recordByRecord query, args...
  
  
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
  SUMMARY_FIELDS = {}
  WIDGETS = {}

# Static method for instantiation. Allows us to provide
# alternate implementations in the future, and pass this function
# around when needed.
Service.connect = (opts = {}) -> new Service(opts)

# Export the Service class to the world
intermine.Service = Service

