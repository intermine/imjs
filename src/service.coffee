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

# The Accept headers that correspond to each data-type.
ACCEPT_HEADER =
    "json": "application/json",
    "jsonobjects": "application/json;type=objects",
    "jsontable": "application/json;type=table",
    "jsonrows": "application/json;type=rows",
    "jsoncount": "application/json;type=count",
    "jsonp": "application/javascript",
    "jsonpobjects": "application/javascript;type=objects",
    "jsonptable": "application/javascript;type=table",
    "jsonprows": "application/javascript;type=rows",
    "jsonpcount": "application/javascript;type=count"

URLENC = "application/x-www-form-urlencoded"

# Import from the appropriate place depending on whether
# if we are in node.js or in the browser.
if IS_NODE
    {_}            = require('underscore')
    {Deferred}     = $ = require('underscore.deferred')
    http           = require('http')
    URL            = require('url')
    qs             = require('querystring')
    {Model}        = require('./model')
    {Query}        = require('./query')
    {List}         = require('./lists')
    {User}         = require('./user')
    funcutils      = require('./util')
    {EventEmitter} = require('events')
    {BufferedResponse} = require('buffered-response')
    to_query_string = qs.stringify
    intermine = exports
else
    {_, jQuery, intermine} = __root__
    {Deferred} = $ = jQuery
    to_query_string = jQuery.param
    {Model, Query, List, User, funcutils} = intermine

    do ->
        converters = {}
        for format, header of ACCEPT_HEADER
            converters["text #{ format }"] = jQuery.parseJSON
        jQuery.ajaxSetup
            accepts: ACCEPT_HEADER
            contents: {json: /json/}
            converters: converters

{get, set, invoke, success, error} = funcutils

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
    merge: "lists/union",
    intersect: "lists/intersect",
    diff: "lists/diff"
WHOAMI_PATH = "user/whoami"
TABLE_ROW_PATH = QUERY_RESULTS_PATH + '/tablerows'
PREF_PATH = 'user/preferences'

# Make a function that lets users know
# when they are trying to use a service that
# isn't supported by their current service.
REQUIRES = (required, got) ->
    "This service requires a service at version #{ required } or above. This one is at #{ got }"

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
        (console.error || console.log)?.apply(console, arguments) if console?

# Process the errors returned from the webservice.
ERROR_PIPE = (xhr, textStatus, e) ->
    try
        JSON.parse(xhr.responseText).error
    catch e
        textStatus

# Produce a factory function that will in turn wrap a
# function and make it suitable for passing on as
# the success callback to an HTTP web-service request.
# @param [String] key The name of the object of interest on the response (optional)
# @return A factory that wraps callbacks for passing as success callbacks
CHECKING_PIPE = (response) -> Deferred ->
    if response.wasSuccessful
        @resolve response
    else
        @reject response.error, response

# Helper function that makes sure a query doesn't have
# any implicit constraints through the use of inner-joins.
# All chains of references will be converted to outer-joins.
dejoin = (q) ->
    for view in q.views
        parts = view.split('.')
        q.addJoin(parts[1..-2].join '.') if parts.length > 2
    return q

# A private helper for a repeated pattern where
# we only fetch a piece of information if it is not
# already available in a instance or static cache.
_get_or_fetch = (propName, store, path, key, cb) ->
    prop = @[propName] ?= if (@useCache and value = store[@root])
        success(value)
    else
        @get(path).pipe(get key).done (x) => store[@root] = x
    prop.done cb

REQUIRES_VERSION = (s, n, f) -> s.fetchVersion().pipe (v) ->
    if v >= n
        f()
    else
        error REQUIRES n, v

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

    # Construct a new connection to a service.
    #
    # @param [Object] options The configuration information used by the service
    # @option options [String] root The base URL of the webservice (required). This
    #   is typically of the form "http://HOST/PATH", eg: "http://www.flymine.org/query"
    # @option options [String] token An authentication token (optional)
    # @option options [(err) ->] A function that handles errors. (optional)
    #   If any errors occur when making HTTP calls to the server, the errors will
    #   be logged by this global error handler, which by default logs to the console.
    #   This can be changed by passing an alternative error handler, such as (->) to
    #   suppress error logging.
    # @option options [boolean] DEBUG Whether to log extra debug information (optional).
    # @option options [String] help An email address to show to the user if help is needed (optional).
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
        @root = @root.replace /ics$/, "ice/"
        @errorHandler ?= DEFAULT_ERROR_HANDLER
        @help ?= 'no.help.available@dev.null'
        @useCache = !noCache # Peristent processed might not want to cache model, version, etc.
        loc = if IS_NODE then '' else location.protocol + '//' + location.host

        @getFormat = (intended = 'json') =>
            unless /jsonp/.test intended # already JSON-P
                unless IS_NODE || jQuery.support.cors # not necessary
                    unless loc.substring(0, @root.length) is @root # Not X-Domain
                        return intended.replace 'json', 'jsonp'

            return intended
    
    # Convenience method for making basic POST requests.
    # @param [String] path The endpoint to post to.
    # @param [Object.<String, String>|Array.<[String, String]>] data parameters to send (optional)
    # @return [Deferred] A promise to perform the request.
    post: (path, data = {}) -> @makeRequest 'POST', path, data

    # Convenience method for making basic GET requests.
    # @param [String] path The endpoint to get from.
    # @param [Object.<String, String>|Array.<[String, String]>] data parameters to send (optional)
    # @return [Deferred] A promise to perform the request.
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
    # @param [Object|Array] data The parameters to send to the service.
    # @param [(data) ->] cb A function that will be called on the results when received.
    # @param [boolean] indiv A flag determinig whether to treat the results as a single block,
    #   or whether to yield individual results to the cb item by item. This only makes sense
    #   in the node.js context. Don't use this.
    #
    # All parameters are optional. 
    #
    # @return [Deferred<?>] A promise to fetch data.
    makeRequest: (method = 'GET', path = '', data = {}, cb = (->), indiv = false) ->
        if _.isArray cb
            [cb, errBack] = cb
        if _.isArray data
            data = _.foldl data, ((m, [k, v]) -> m[k] = v; m), {}

        url = @root + path
        errBack ?= @errorHandler
        data.token = @token if @token
        data.format = @getFormat(data.format)

        if /jsonp/.test data.format
            # tunnel the true method
            data.method = method
            method = 'GET'
            url += '?callback=?'

        # IE requires that we tunnel DELETE and PUT
        unless @supports method
            data.method = method
            method = @getEffectiveMethod method

        if method is 'DELETE'
            # grumble grumble struts grumble grumble...
            # (struts won't read query data from the request body
            # of DELETE requests).
            url += '?' + to_query_string data

        opts =
            data: data,
            dataType: data.format,
            success: cb,
            error: errBack,
            url: url,
            type: method

        return @doReq(opts, indiv)

    # Whether or not this service supports the given method
    # The default implementation returns true for all inputs.
    supports: -> true

    # Get the method we should actually use to make a request of
    # method 'x'.
    #
    # @param [String] x The method I'm thinking of using.
    getEffectiveMethod: (x) -> x

    # Get the results of using a list enrichment widget to calculate
    # statistics for a set of objects. An enrichment calculation
    # attempts to find related items that are particularly characteristic
    # of the items in this list.
    # @param [Object<String, String>] opts The parameters to pass to the calculation.
    # @option opts [String] list The name of the list to analyse.
    # @option opts [String] widget The name of the enrichment calculation to use.
    # @option opts [Float] maxp The maximum permissible p-value (optional, default = 0.05).
    # @option opts [String] population The name of a list to use as a background population (optional).
    # @option opts [String] filter An extra value that some widget calculations accept.
    # @return [Deferred<Array<Object>>] A promise to get results.
    enrichment: (opts, cb) -> REQUIRES_VERSION @, 8, =>
        @get(ENRICHMENT_PATH, _.defaults {}, opts, maxp: 0.05).pipe(get 'results').done(cb)

    # Search for items in the database by any term or facet.
    #
    # This method performs a wide-ranging free-text search (powered
    # by Lucene) for items in the database matching a given term. The data
    # returned is limited to a precalculated document of key-fields for 
    # each object. To further explore the dataset, the user will
    # want to construct more sophisticated queries. See {@link Query}.
    #
    # @param [Object] options A collection of parameters.
    # @param [(Array.<Object>, Object, Object) ->] An optional call-back function.
    # @option options [String] q The term to search by.
    # @option options [Object<String, String>] facets A set of facet constraints.
    # @return [Deferred.<Array, Object, Object>] A promise to search the database.
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
    # @param [Query|Object] The query to run. If it is not already instantiated
    #   as a Query object, it will be, so the JSON definition of a query can be used
    #   here.
    # @param [(Number) ->] cb A callback that receives a number. Optional.
    # @return [Deferred] A promise to yield a count.
    count: (q, cb) =>
        if q.toXML?
            req = {query: q.toXML(), format: 'jsoncount'}
            @post(QUERY_RESULTS_PATH, req).pipe(get 'count').done(cb)
        else
            @query(q).pipe(@count).done(cb)

    # Retrieve a representation of a specific object.
    # @param [String] type The type of the object to find (eg: Gene)
    # @param [Number] id The internal DB id of the object.
    # @param [(obj) ->] A callback that receives an object. (optional).
    # @return [Deferred] A promise to yield an object.
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
    # @param [(Array.<Object>) ->] cb A callback that receives an Array of objects. (optional).
    # @return [Deferred.<Array.<Object>>] A promise to yield an array of objects.
    find: (type, term, cb) ->
        @query(from: type, select: ['**'], where: [[type, 'LOOKUP', term]])
            .pipe(dejoin)
            .pipe(invoke 'records')
            .done(cb)

    # Retrieve information about the currently authenticated user.
    # @param [(User) ->] A callback the receives a User object.
    # @return [Deferred.<User>] A promise to yield a user.
    whoami: (cb) -> REQUIRES_VERSION @, 9, =>
        @get(WHOAMI_PATH).pipe(get 'user').pipe((x) => new User(@, x)).done(cb)

    doPagedRequest: (q, path, page = {}, format, cb) ->
        if q.toXML?
            req = _.defaults {}, {query: q.toXML(), format: format}, page
            @post(path, req).pipe(get 'results').done(cb)
        else
            @query(q).pipe((query) => @doPagedRequest(query, path, page, format, cb))

    table: (q, page, cb) => @doPagedRequest(q, QUERY_RESULTS_PATH, page, 'jsontable', cb)

    records: (q, page, cb) => @doPagedRequest(q, QUERY_RESULTS_PATH, page, 'jsonobjects', cb)

    rows: (q, page, cb) => @doPagedRequest(q, QUERY_RESULTS_PATH, page, 'json', cb)

    tableRows: (q, page, cb) => @doPagedRequest(q, TABLE_ROW_PATH, page, 'json', cb)

    fetchTemplates: (cb) => @get(TEMPLATES_PATH).pipe(get 'templates').done(cb)

    fetchLists: (cb) -> @findLists '', cb

    findLists: (name, cb) ->
        fn = (ls) => (new List(data, @) for data in ls)
        @get(LISTS_PATH, {name}).pipe(get 'lists').pipe(fn).done(cb)

    fetchList: (name, cb) => @fetchVersion().pipe (v) =>
        if v < 13
            @fetchLists().pipe(getListFinder(name)).done(cb)
        else
            @findLists(name).pipe(get 0).done(cb)

    fetchListsContaining: (opts, cb) =>
        fn = (xs) => (new List(x, @) for x in xs)
        @get(WITH_OBJ_PATH, opts).pipe(get 'lists').pipe(fn).done(cb)

    combineLists: (operation, options, cb) ->
        req = _.pick options, 'name', 'description'
        req.tags = options.tags.join(';')
        req.lists = options.lists.join(';')
        @get(LIST_OPERATION_PATHS[operation], req).pipe(get 'listName').pipe(@fetchList).done(cb)

    # Combine two or more lists through a union operation.
    merge: -> @combineLists 'merge', arguments...

    # Combine two or more lists through an intersection operation.
    intersect: -> @combineLists 'intersect', arguments...

    # Combine two more lists through a symmetric difference opertation.
    diff: -> @combineLists 'diff', arguments...

    # The following methods fetch resources that can be considered
    # stable - they are not expected to change between releases of
    # the web-service. Lonk running processes should take care either to
    # set 'noCache' on the service, or to regularly call Service.flush().

    # Fetch the list widgets that are available from this service.
    # @return [Deferred<Array<Object>>] A promise to return a list of widgets.
    fetchWidgets: (cb) -> REQUIRES_VERSION @, 8, =>
        _get_or_fetch.call @, 'widgets', WIDGETS, WIDGETS_PATH, 'widgets', cb

    # Fetch the description of the data model for this service.
    # @return [Deferred<Model>] A promise to return metadata about this service.
    fetchModel: (cb) ->
        _get_or_fetch.call(@, 'model', MODELS, MODEL_PATH, 'model')
            .pipe(Model.load)
            .pipe(set service: @)
            .done(cb)

    # Fetch the configured summary-fields.
    # The summary fields describe which fields should be used to summarise each class.
    # @return [Deferred<Object<String, Array<String>>>] A promise to return a mapping
    #   from class-name to a list of paths.
    fetchSummaryFields: (cb) ->
        _get_or_fetch.call @, 'summaryFields', SUMMARY_FIELDS, SUMMARYFIELDS_PATH, 'classes', cb

    # Fetch the number that describes the web-service capabilities.
    # @return [Deferred<Number>] A promise to return a version number.
    fetchVersion: (cb) ->
        _get_or_fetch.call @, 'version', VERSIONS, VERSION_PATH, 'version', cb

    # Promise to make a new Query.
    #
    # @param [Object] options The JSON representation of the query.
    # @param [(Query) ->] cb An optional callback to be called when the query is made.
    # @return [Deferred<Query>] A promise to make a new query.
    query: (options, cb) => $.when(@fetchModel(), @fetchSummaryFields()).pipe (m, sfs) =>
        args = _.defaults {}, options, {model: m, summaryFields: sfs}
        service = @
        Deferred ->
            @fail(service.errorHandler)
            @done(cb)
            try # The whole point of this is to catch errors.
                @resolve new Query(args, service)
            catch e
                @reject e

    manageUserPreferences: (method, data) -> REQUIRES_VERSION @, 11, =>
        @makeRequest(method, PREF_PATH, data).pipe(get 'preferences')
    
wire_for_node = ->

    # Pattern to match optional trailing commas
    PESKY_COMMA = /,\s*$/

    iterReq = (format) -> (q, page = {}, cbs = []) ->
        if !cbs? and not (page.start? or page.size?)
            [page, cbs] = [{}, page]
        if _.isFunction cbs
            cbs = [cbs]
        req = _.extend {format}, page, query: q.toXML()
        [doThis, onErr, onEnd] = cbs
        @makeRequest('POST', QUERY_RESULTS_PATH, req, null, true)
            .fail(onErr)
            .done(invoke 'each', doThis)
            .done(invoke 'error', onErr)
            .done(invoke 'done', onEnd)

    Service::rowByRow = iterReq 'json'

    Service::recordByRecord = iterReq 'jsonobjects'

    streaming = (ret, opts) -> (resp) ->
        containerBuffer = ''
        char0 = if opts.data.format is 'json' then '[' else '{'
        charZ = if opts.data.format is 'json' then ']' else '}'
        toItem = (line, idx) ->
            try
                parsed = JSON.parse line.replace PESKY_COMMA, ''
                return parsed
            catch e
                containerBuffer += line
                lastChar = line[line.length - 1]
                if idx > 0 and (lastChar is ',' or (lastChar is char0 && line[0] is charZ))
                    # This should have parsed
                    iter.emit('error', e, line)
                return undefined
        onlyDefinedItems = (item) -> item?
        onEnd = ->
            # Check the container on end to make sure all was well.
            try
                container = JSON.parse containerBuffer
                if container.error
                    iter.emit 'error', new Error(container.error)
            catch e
                iter.emit 'error', "Mal-formed JSON response: #{ containerBuffer }"

        iter = new BufferedResponse(resp, 'utf8')
            .map(toItem)
            .filter(onlyDefinedItems)
            .each(opts.success)
            .error(opts.error)
            .done(onEnd)

        ret.resolve iter

    blocking = (ret, opts) -> (resp) ->
        containerBuffer = ''
        ret.done(opts.success)
        resp.on 'data', (chunk) -> containerBuffer += chunk
        resp.on 'error', (e) -> ret.reject(e)
        resp.on 'end', ->
            if /json/.test opts.data.format
                if '' is containerBuffer and resp.statusCode is 200
                    # No body, but all-good.
                    ret.resolve()
                else
                    try
                        parsed = JSON.parse containerBuffer
                        if err = parsed.error
                            ret.reject new Error(err)
                        else
                            ret.resolve parsed
                    catch e
                        if resp.statusCode >= 400
                            ret.reject new Error(resp.statusCode)
                        else
                            ret.reject new Error "Could not parse response to #{ opts.type } #{ opts.url }: '#{ containerBuffer }' (#{ e })"
            else
                if e = containerBuffer.match /\[Error\] (\d+)(.*)/m
                    ret.reject new Error(e[2])
                else
                    ret.resolve containerBuffer

    Service::doReq = (opts, iter) -> Deferred ->
        @fail opts.error
        @done opts.success
        if _.isString opts.data
            postdata = opts.data
            if opts.type in [ 'GET', 'DELETE' ]
                return ret.reject("Invalid request. #{ opts.type } requests must not have bodies")
        else
            postdata = to_query_string opts.data
        url = URL.parse(opts.url, true)
        url.method = opts.type
        url.port = url.port || 80
        url.headers =
            'User-Agent': 'node-http/imjs',
            'Accept': ACCEPT_HEADER[opts.dataType]
        if url.method in ['GET', 'DELETE'] and _.size opts.data
            url.path += '?' + postdata
        else
            url.headers['Content-Type'] = (opts.contentType or URLENC) + '; charset=UTF-8'
            url.headers['Content-Length'] = postdata.length

        req = http.request url, (if iter then streaming else blocking) @, opts

        req.on 'error', @reject

        if url.method in [ 'POST', 'PUT' ]
            req.write postdata
        req.end()


wire_for_browser = ->

    if XDomainRequest?
        mapping = PUT: 'POST', DELETE: 'GET'
        Service::getEffectiveMethod = (x) -> mapping[x]
        Service::supports = (m) -> mapping[m] is m

    wrapCbs = (cbs) ->
        if _.isArray cbs
            [doThis, err, atEnd] = cbs
            [((rows) -> _.each(rows, doThis)), err, atEnd]
        else
            [(rows) -> _.each rows, cbs]

    iterReq = (format) -> (q, page = {}, cbs = []) ->
        if !cbs? and not (page.start? or page.size?)
            [page, cbs] = [{}, page]
        _cbs = wrapCbs(cbs)
        req = _.extend {format}, page, query: q.toXML()
        [doThis, fail, onEnd] = _cbs
        @post(QUERY_RESULTS_PATH, req, _cbs).done(onEnd)

    # TODO: make these work with finally callback.
    Service::rowByRow = iterReq 'json'

    Service::recordByRecord = iterReq 'jsonobjects'

    Service::doReq = (opts) ->
        errBack = (opts.error or @errorHandler)
        opts.error = _.compose errBack, ERROR_PIPE
        return jQuery.ajax(opts).pipe(CHECKING_PIPE).fail(errBack)

if IS_NODE
    wire_for_node()
else
    wire_for_browser()

Service::eachRow = Service::rowByRow
Service::eachRecord = Service::recordByRecord

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
# alternate implementations in the future.
Service.connect = (opts) -> new Service(opts)

# Export the Service class to the world
intermine.Service = Service
# And re-export the other public classes if in node.js
intermine.Model ?= Model
intermine.Query ?= Query
intermine.List ?= List
intermine.User ?= User
