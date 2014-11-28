# This module supplies the **Query** class for the **im.js**
# web-service client.
#
# Queries are representations of requests for data to a web-service.
# They abstract the path-query object interface which is exposed
# by the InterMine API.
#
# This library is designed to be compatible with both node.js
# and browsers.

intermine       = exports
intermine.xml   = require('./xml')
utils           = require './util'

{REQUIRES_VERSION, withCB, merge, filter, partition, fold, concatMap, id, get, invoke} = utils
toQueryString   = utils.querystring

get_canonical_op = (orig) ->
  canonical = if orig?.toLowerCase? then Query.OP_DICT[orig.toLowerCase()] else null
  unless canonical
    throw new Error "Illegal constraint operator: #{ orig }"
  canonical

BASIC_ATTRS  = [ 'path', 'op', 'code' ]
SIMPLE_ATTRS = BASIC_ATTRS.concat [ 'value', 'extraValue' ]

RESULTS_METHODS = [
  'rowByRow', 'eachRow', 'recordByRecord', 'eachRecord',
  'records', 'rows', 'table', 'tableRows', 'values'
]

LIST_PIPE = (service) -> utils.compose service.fetchList, get 'listName'

# The valid codes for a query
CODES = [
  null, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
  'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
]

# Return a string with the head cut off.
#
# @example
#   decapitate('Foo.bar.baz') #=> 'bar.baz'
#
# @private
# @param [String] x A path string
# @return [String] The path without its head.
decapitate = (x = '') -> x.substr(x.indexOf('.'))

# Constraint XML machinery

# Stringify a constraint value from a multi-value constraint.
# @private
# @param [String] v The constraint value.
# @return [String] An XML serialisation of the value.
conValStr = (v) -> if v? then "<value>#{utils.escape v}</value>" else "<nullValue/>"

# Stringify the attributes for a constraint.
# @private
# @param [Constraint] c The constraint to serialise.
# @param [Array<String>] names The names of properties on the constraint to serialise.
# @return [String] An serialisation of the constraint's attributes.
conAttrs = (c, names) ->
  ("""#{k}="#{utils.escape(v)}" """ for k, v of c when (k in names)).join('')

# Stringify a constraint that has no value attribute.
# @private
# @param [OperatorConstraint] c The constraint to serialise.
# @return [String] The XML serialisation of the constraint.
noValueConStr = (c) -> """<constraint #{ conAttrs(c, BASIC_ATTRS) }/>"""

# Stringify a constraint that restricts an object to a type.
# @private
# @param [SubTypeConstraint] c The constraint to serialise.
# @return [String] The XML serialization of the constraint.
typeConStr = (c) -> """<constraint #{ conAttrs(c, ['path', 'type']) }/>"""

# Stringify a constraint that has a value.
# @private
# @param [ValueConstraint] c The constraint to serialise.
# @return [String] The XML serialization of the constraint.
simpleConStr = (c) -> """<constraint #{ conAttrs(c, SIMPLE_ATTRS) }/>"""

# Stringify a constraint that has multiple values.
# @private
# @param [MultiValueConstraint] c The constraint to serialise.
# @return [String] The XML serialization of the constraint.
multiConStr = (c) ->
  """<constraint #{ conAttrs(c, BASIC_ATTRS) }>#{concatMap(conValStr) c.values}</constraint>"""

# Stringify a constraint that has multiple values.
# @private
# @param [IdsContraint] c The constraint to serialise.
# @return [String] The XML serialization of the constraint.
idConStr = (c) -> """<constraint #{ conAttrs(c, BASIC_ATTRS) }ids="#{c.ids.join(',')}"/>"""

# Stringify a constraint that has multiple values.
# @private
# @param [Constraint] c The constraint to serialise.
# @return [String] The XML serialization of the constraint.
conStr = (c) ->
  if c.values?
    multiConStr(c)
  else if c.ids?
    idConStr(c)
  else if !c.op?
    typeConStr(c)
  else if c.op in Query.NULL_OPS
    noValueConStr(c)
  else
    simpleConStr(c)

headLess = (path) -> path.replace /^[^\.]+\./, ''

# Copy a constraint.
#
# Produce an identical but unconnected copy of a constraint.
# @private
# @param [Constraint] con The constraint to copy.
# @return [Constraint] An identical copy of the constraint.
copyCon = (con) ->
  {path, type, op, value, values, extraValue, ids, code, editable, switched, switchable} = con
  ids = ids?.slice()
  values = values?.slice()
  noUndefVals {
    path, type, op, value, values, extraValue, ids, code,
    editable, switched, switchable
  }

# Produce the JSON representation of a constraint.
#
# @private
# @param [Constraint] The constraint to JSONify.
# @return [Object] The JSON representation.
conToJSON = (con) ->
  copy = copyCon con
  copy.path = headLess copy.path
  return copy

# Remove all properties of the input object that are undefined.
# @private
# @param [Object] The object to strip.
# @return [Object] The same object as was provided as input.
noUndefVals = (x) ->
  for k, v of x
    delete x[k] unless v?
  return x

# Get an error message for when we don't manage to remove constraints correctly,
# @private
# @param [Array<Constraint>] orig The original set of constraints.
# @param [Array<Constraint>] reduced The current set of constraints.
# @return [String] A message explaining this.
didntRemove = (orig, reduced) ->
  "Did not remove a single constraint. original = #{ orig }, reduced = #{ reduced }"

interpretConstraint = (path, con) ->
  constraint = {path}
  if con is null
    constraint.op = 'IS NULL'
  else if utils.isArray con
    constraint.op = 'ONE OF'
    constraint.values = con
  else if typeof con in ['string', 'number', 'boolean']
    if con.toUpperCase?() in Query.NULL_OPS
      constraint.op = con
    else
      constraint.op = '='
      constraint.value = con
  else
    keys = (k for k, x of con)
    if 'isa' in keys
      if utils.isArray(con.isa)
        constraint.op = k
        constraint.values = con.isa
      else
        constraint.type = con.isa
    else
      if 'extraValue' in keys
        constraint.extraValue = con.extraValue
      for k, v of con when (k isnt 'extraValue')
        constraint.op = k
        if utils.isArray(v)
          constraint.values = v
        else
          constraint.value = v
  return constraint

interpretConArray = (conArgs) ->
  conArgs = conArgs.slice()
  constraint = path: conArgs.shift()
  if conArgs.length is 1
    a0 = conArgs[0]
    if a0.toUpperCase?() in Query.NULL_OPS
      constraint.op = a0
    else
      constraint.type = a0
  else if conArgs.length >= 2
    constraint.op = conArgs[0]
    v = conArgs[1]
    if utils.isArray(v)
      constraint.values = v
    else
      constraint.value = v
    if conArgs.length == 3
      constraint.extraValue = conArgs[2]
  return constraint

stringToSortOrder = (str) ->
  return [] unless str?
  parts = str.split /\s+/
  pathIndices = (x * 2 for x in [0 ... (parts.length / 2)])
  ([parts[i], parts[i + 1]] for i in pathIndices)

removeIrrelevantSortOrders = ->
  oldOrder = @sortOrder
  @sortOrder = (oe for oe in oldOrder when @isRelevant oe.path)
  if oldOrder.length isnt @sortOrder.length
    @trigger 'change:sortorder change:orderby', @sortOrder.slice()

class Query
  @JOIN_STYLES = ['INNER', 'OUTER']
  @BIO_FORMATS = ['gff3', 'fasta', 'bed']
  @NULL_OPS = ['IS NULL', 'IS NOT NULL']
  @ATTRIBUTE_VALUE_OPS = ["=", "!=", ">", ">=", "<", "<=", "CONTAINS", "LIKE", "NOT LIKE"]
  @MULTIVALUE_OPS = ['ONE OF', 'NONE OF']
  @TERNARY_OPS = ['LOOKUP']
  @LOOP_OPS = ['=', '!=']
  @LIST_OPS = ['IN', 'NOT IN']

  @OP_DICT =
    '=' : '='
    '==': '=='
    'eq': '='
    'eqq': '=='
    '!=': '!='
    'ne': '!='
    '>' : '>'
    'gt' : '>'
    '>=': '>='
    'ge': '>='
    '<': '<'
    'lt': '<'
    '<=': '<='
    'le': '<='
    'contains': 'CONTAINS'
    'CONTAINS': 'CONTAINS'
    'does not contain': 'DOES NOT CONTAIN'
    'DOES NOT CONTAIN': 'DOES NOT CONTAIN'
    'like': 'LIKE'
    'LIKE': 'LIKE'
    'not like': 'NOT LIKE'
    'NOT LIKE': 'NOT LIKE'
    'lookup': 'LOOKUP'
    'IS NULL': 'IS NULL'
    'is null': 'IS NULL'
    'IS NOT NULL': 'IS NOT NULL'
    'is not null': 'IS NOT NULL'
    'ONE OF': 'ONE OF'
    'one of': 'ONE OF'
    'NONE OF': 'NONE OF'
    'none of': 'NONE OF'
    'in': 'IN'
    'not in': 'NOT IN'
    'IN': 'IN'
    'NOT IN': 'NOT IN'
    'WITHIN': 'WITHIN'
    'within': 'WITHIN'
    'OVERLAPS': 'OVERLAPS'
    'overlaps': 'OVERLAPS'
    'DOES NOT OVERLAP': 'DOES NOT OVERLAP'
    'does not overlap': 'DOES NOT OVERLAP'
    'OUTSIDE': 'OUTSIDE'
    'outside': 'OUTSIDE'
    'ISA': 'ISA'
    'isa': 'ISA'

  # Bind a callback to an event.
  #
  # An implementation of the EventEmitter API, allowing clients to subscribe
  # to events on {Query}s.
  # @param [String] events A space separated set of events to subscribe to.
  # @param [Function] callback The event-handler.
  # @param [Object] context The context to bind as this for the callback (optional).
  # @return [Query] This query, for chaining.
  on: (events, callback, context) ->
    events = events.split /\s+/
    calls = (@_callbacks ?= {})
    while ev = events.shift()
      list = (calls[ev] ?= {})
      tail = (list.tail ?= (list.next = {}))
      tail.callback = callback
      tail.context = context
      list.tail = tail.next = {}
    this

  # alias for {#on}
  bind: (args...) -> @on.apply(@, args)

  # Remove a particular event handler, or a more general collection.
  #
  # @overload off()
  #   Unbinds all event handlers.
  #   @return [Query] this query, for chaining.
  #
  # @overload off(events)
  #   Unbinds all event handlers for the given events.
  #   @param [String] events A space separated set of event names.
  #   @return [Query] this query, for chaining.
  #
  # @overload off(events, handler)
  #   Unbinds the given handler for the given events.
  #   @param [String] events A space separated set of event names.
  #   @param [Function] handler The event handler to unbind.
  #   @return [Query] this query, for chaining.
  #
  # @overload off(events, handler, context)
  #   Unbinds the given handler from all the given events where is it is bound with
  #   the given context.
  #   @param [String] events A space separated set of event names.
  #   @param [Function] handler The event handler to unbind.
  #   @param [Object] context The `this` for the handler.
  #   @return [Query] this query, for chaining.
  #
  off: (events, callback , context) ->
    unless events?
      @_callbacks = {}
      return this

    events = events.split /\s+/
    calls = (@_callbacks ?= {})
    for ev in events
      if callback?
        current = linkedList = (calls[ev] or {})
        last = linkedList.tail
        while ((node = current.next) isnt last)
          remove = (not context? or node.context is context) and (callback is node.callback)
          if remove
            current.next = (node.next or last)
            node = current
          else
            current = node
      else
        delete calls[ev]

    return this

  # alias for {#off}
  unbind: (args...) -> @off args...

  # Bind an event to be executed once, and then unbound.
  #
  # @param [String] events A space separated set of event names.
  # @param [Function] callback The event handler.
  # @param [Object] context The `this` for the event handler.
  # @return [Query] this query, for chaining.
  # @see #on
  once: (events, callback, context) ->
    f = (args...) =>
      callback.apply(context, args)
      @off(events, f)
    @on(events, f)

  # Alias for {#trigger}
  emit: (args...) -> @trigger args...

  # Trigger a given set of events.
  # @param [String] events A space separated set of event names.
  # @param [Array<Object>] args The arguments to send to the handlers.
  # @return [Query] this query, for chaining.
  trigger: (events, rest...) ->
    calls = @_callbacks
    unless calls
      return @
    all = calls['all']
    (events = events.split(/\s+/)).push null
    while event = events.shift()
      events.push(next: all.next, tail: all.tail, event: event) if all
      continue unless (node = calls[event])
      events.push(next: node.next, tail: node.tail)

    while node = events.pop()
      tail = node.tail
      args = if node.event then [node.event].concat(rest) else rest
      while ((node = node.next) isnt tail)
        node.callback.apply(node.context || this, args)

    this

  qAttrs = ['name', 'view', 'sortOrder', 'constraintLogic', 'title', 'description', 'comment']
  cAttrs = ['path', 'type', 'op', 'code', 'value', 'ids']
  toAttrPairs = (el, attrs) -> ([x, el.getAttribute(x)] for x in attrs when el.hasAttribute(x))
  kids = (el, name) -> (kid for kid in el.getElementsByTagName(name))
  xmlAttr = (name) -> (el) -> el.getAttribute name

  # Load the first query found in the XML.
  #
  # @param [String] The serialised PathQuery XML
  # @return [Object] The JSON representation of the Query, suitable for passing
  #                  to `new Query(json)`.
  # @throw Error if there is no query in the XML, or if XML is invalid.
  @fromXML: (xml) ->
    dom = intermine.xml.parse xml
    query = (kids(dom, 'query')[0] or kids(dom, 'template')[0])
    unless query
      throw new Error("no query in xml")

    pathOf = xmlAttr 'path'
    styleOf = xmlAttr 'style'

    q = utils.pairsToObj toAttrPairs query, qAttrs
    q.view = q.view.split /\s+/
    q.sortOrder = stringToSortOrder q.sortOrder
    q.joins = (pathOf j for j in kids(query, 'join') when styleOf(j) is 'OUTER')
    q.constraints = for con in kids(query, 'constraint') then do (con) ->
      c = utils.pairsToObj toAttrPairs con, cAttrs
      c.ids = (parseInt(x, 10) for x in c.ids.split(',')) if c.ids?
      values = kids(con, 'value')
      if values.length
        c.values = ((tn.data for tn in v.childNodes).join('') for v in values)
      c

    return q

  constraints: []
  views: []
  joins: {}
  constraintLogic: ''
  sortOrder: ''
  name: null
  title: null
  comment: null
  description: null

  # Construct a new Query object from a set of properties.
  #
  # @param [Object] properties The options that define the query.
  # @param [Service] The service this query belongs to.
  #
  # # All options are optional. Alternative names permitted are separated by bars.
  # @option properties [Object<String, String>] aliases|displayNames Display names
  #         to be used for given paths.
  # @option properties [Model] model The model this query is over.
  # @option properties [Object<String, Array<String>>] summaryFields The fields to use
  #         when expanding `*` paths.
  # @option properties [String] root|from The root of the query (eg. `Gene`).
  # @option properties [Number] size|limit|maxRows The maximum number of rows to return.
  # @option properties [Number] start|offset The index of the first row to return.
  # @option properties [Array<String>] views|view|select The columns to return as output.
  # @option properties [Array<Constraint>, Object] constraints|where The constraints.
  # @option properties [Array<String>,Array<Join>] joins|join The outer-joins.
  # @option properties [Array<String>,Array<SortOrderElement>] sortOrder|orderBy The
  #         paths to use to determine the sort-order.
  # @option properties [String] constraintLogic The constraint logic.
  #
  constructor: (properties, service, {model, summaryFields} = {}) ->
    properties ?= {}
    # Fresh containers collection properties.
    @constraints = []
    @views = []
    @joins = {}
    @displayNames = utils.copy (properties.displayNames ? properties.aliases ? {})

    # Copy over name, title, etc
    for prop in ['name', 'title', 'comment', 'description', 'type'] when properties[prop]?
      @[prop] = properties[prop]

    @service       = service ? {}
    @model         = model ? properties.model ? {}
    @summaryFields = summaryFields ? properties.summaryFields ? {}
    @root = properties.root ? properties.from
    @maxRows = properties.size ? properties.limit ? properties.maxRows
    @start = properties.start ? properties.offset ? 0

    @select(properties.views or properties.view or properties.select or [])
    @addConstraints(properties.constraints or properties.where or [])
    @addJoins(properties.joins or properties.join or [])
    @orderBy(properties.sortOrder or properties.orderBy or [])

    @constraintLogic = properties.constraintLogic if properties.constraintLogic?


    @on 'change:views', removeIrrelevantSortOrders, @

  # Remove the given paths from the select list.
  #
  # @param [Array<String>,Array<PathInfo>,String,PathInfo] The paths to remove from the
  #        list of selected columns.
  # @return [Query] This query, for chaining.
  removeFromSelect: (unwanted = []) ->
    unwanted = utils.stringList unwanted
    mapFn = utils.compose(@expandStar, @adjustPath)
    unwanted = utils.flatten (mapFn uw for uw in unwanted)
    @sortOrder = (so for so in @sortOrder when not (so.path in unwanted))
    @views = (v for v in @views when not (v in unwanted))
    @trigger('remove:view', unwanted)
    @trigger('change:views', @views)

  removeConstraint: (con, silent = false) ->
    orig = @constraints
    iscon = if (typeof con is 'string')
      ((c) -> c.code is con)
    else
      ((c) -> (c.path is con.path) and
        (c.op is con.op) and (c.value is con.value) and
        (c.extraValue is con.extraValue) and (con.type is c.type) and
        (c.values?.join('%%') is con.values?.join('%%')))

    reduced = (c for c in orig when (not iscon c))

    if reduced.length isnt orig.length - 1
      throw new Error didntRemove orig, reduced

    @constraints = reduced
    unless silent
      @trigger 'change:constraints'
      @trigger 'removed:constraint', utils.find orig, iscon

  # Add an element to the select list.
  addToSelect: (views = []) ->
    views = utils.stringList views
    mapFn = utils.compose @expandStar, @adjustPath
    toAdd = utils.flatten (mapFn v for v in views)
    dups = (p for p in toAdd when p in @views)
    if dups.length
      throw new Error "#{ dups } already in the select list"
    dups = (p for p in toAdd when (x for x in toAdd when x is p).length > 1)
    if dups.length
      throw new Error "#{ dups } specified multiple times as arguments to addToSelect"
    @views.push toAdd...
    @trigger('add:view change:views', toAdd)

  # Replace the existing select list with the one passed as an argument.
  select: (views) =>
    oldViews = @views.slice()
    try
      @views = []
      @addToSelect views
    catch e
      @views = oldViews
      utils.error e
    @

  # Interpret an argument as resolve the canonical path it refers to.
  # For example, if the root of this query is known, then this method will
  # check that the path has the same root, and add it if it is absent.
  adjustPath: (path) =>
    path = if (path && path.name) then path.name else "" + path
    if @root?
      path = @root + "." + path unless path.match "^" + @root
    else
      @root = path.split('.')[0]
    path

  getPossiblePaths: (depth = 3) ->
    getPaths = (root, d) =>
      ret = [root]
      path = @getPathInfo(root)
      if path.isAttribute()
        ret
      else
        cd = @getPathInfo(root).getType()
        subPaths = concatMap (ref) -> getPaths "#{ root }.#{ ref.name }", d - 1
        others = if cd and (d > 0) then (subPaths (field for name, field of cd.fields)) else []

        ret.concat others

    @_possiblePaths ?= {}
    @_possiblePaths[depth] ?= getPaths @root, depth

  getPathInfo: (path) ->
    adjusted = @adjustPath path
    pi = @model?.getPathInfo?(adjusted, @getSubclasses())
    pi.displayName = @displayNames[adjusted] if (pi and adjusted of @displayNames)
    return pi

  makePath: Query::getPathInfo

  # Get the mapping from path to class-name that is defined by the
  # subtype constraints.
  toPathAndType = (c) -> [c.path, c.type]
  scFold = utils.compose utils.pairsToObj, utils.map(toPathAndType), filter get 'type'
  getSubclasses: -> scFold @constraints

  # Get the type of a path.
  getType: (path) -> @getPathInfo(path).getType()

  # Get all the nodes present in the view. A node is defined as the PathInfo object
  # representing the class or reference that the attributes selected in the view belong to.
  getViewNodes: ->
    toParentNode = (v) => @getPathInfo(v).getParent()
    utils.uniqBy String, (toParentNode p for p in @views)

  # Check to see whether a path is in the view. This method responds correctly
  # whether the argument is a full path string, a headless path string, or a
  # PathInfo object. If the path represents an attribute path then it is a simple
  # index look up of the view. If the argument represents a reference path, then
  # this method returns true if any of the views descends from that path.
  isInView: (path) ->
    pi = @getPathInfo(path)
    throw new Error("Invalid path: #{ path }") unless pi
    if pi.isAttribute()
      return pi.toString() in @views
    else
      pstr = pi.toString()
      return utils.any @getViewNodes(), (n) -> n.toString() is pstr

  # Check to see whether a path is constrained to a value. If the includeAttrs
  # parameter is true, then this method will return true if any of the attributes
  # of the class referenced by this path are constrained to a value. Type constraints
  # are not considered in this analysis.
  #
  # @param [String|PathInfo] path The path to check.
  # @param [boolean] includeAttrs Whether to include attributes.
  #
  # @return Whether or not this path is constrained.
  isConstrained: (path, includeAttrs = false) ->
    pi = @getPathInfo(path)
    throw new Error("Invalid path: #{ path }") unless pi
    test = (c) -> c.op? and c.path is pi.toString()

    if (not pi.isAttribute()) and includeAttrs
      test = (c) =>
        c.op? and (c.path is pi.toString() or pi.equals @getPathInfo(c.path).getParent())
    return utils.any @constraints, test

  # Return true is the path passed as an argument could possibly
  # represent multiple values (this is true when any of the nodes that
  # the path descends from represents a collection of values.
  canHaveMultipleValues: (path) -> @getPathInfo(path).containsCollection()

  # Get all the nodes present to the query, whether they are in the views,
  # or the constraints.
  getQueryNodes: () ->
    viewNodes = @getViewNodes()
    constrainedNodes = for c in @constraints when not c.type?
      pi = @getPathInfo(c.path)
      if pi.isAttribute() then pi.getParent() else pi
    utils.uniqBy String, viewNodes.concat(constrainedNodes)

  isInQuery: (p) ->
    pi = @getPathInfo p
    if pi
      pstr = pi.toPathString()
      for p in @views.concat(c.path for c in @constraints when not c.type?)
        return true if 0 is p.indexOf pstr
      return false
    return true # No model available - for testing return true.

  isRelevant: (path) ->
    pi = @getPathInfo path
    pi = pi.getParent() if pi.isAttribute()
    sought = pi.toString()
    nodes = @getViewNodes()
    return utils.any nodes, (n) -> n.toPathString() is sought

  # Interpret a path that might end in '*' or '**' as the
  # set of default paths it represent.
  expandStar: (path) =>
    if /\*$/.test(path)
      pathStem = path.substr(0, path.lastIndexOf('.'))
      expand = (x) -> pathStem + x
      cd = @getType(pathStem)
      if /\.\*$/.test(path)
        if cd and @summaryFields[cd.name]
          fn = utils.compose expand, decapitate
          return (fn n for n in @summaryFields[cd.name] when (not @hasView(n)))
      else if /\.\*\*$/.test(path) # same as summary fields, plus all attributes.
        starViews = @expandStar(pathStem + '.*')
        attrViews = (expand ".#{ name }" for name of cd.attributes)
        return utils.uniqBy id, starViews.concat(attrViews)

    return path

  isOuterJoin: (p) -> @joins[@adjustPath(p)] is 'OUTER'

  hasView: (v) -> @views and @adjustPath(v) in @views

  # Get a promise to yield a count.
  #
  # @param [Function<Number>] cont An optional callback.
  # @return [Promise<Number>] A promise to yield a number representing the number of rows.
  count: (cont) ->
    if @service.count
      @service.count(@, cont)
    else
      throw new Error("This query has no service with count functionality attached.")

  # Add the results of this query to a list on the server.
  #
  # @param [String|List] target The list to add results to.
  # @returns [Promise<List>] A promise to yield the updated list information.
  appendToList: (target, cb) ->
    if target?.name # Target is list.
      name = target.name
      updateTarget = (err, list) -> target.size = list.size unless err?
    else
      name = String target
      updateTarget = null
    toRun = @makeListQuery()
    req =
      listName: name
      query: toRun.toXML()

    processor = LIST_PIPE @service

    withCB updateTarget, cb, @service.post('query/append/tolist', req).then processor

  # Get a clone of this query with the given paths selected.
  #
  # The clone may have constraints added to it to preserve the implied constraints
  # that result from the default inner-join status of paths.
  #
  # We ensure we aren't changing the query by removing implicit
  # join constraints; these implicit constraints are replaced with
  # explicit constraints. This only works with joins on objects that
  # have ids; you will have to handle simple objects yourself.
  #
  # @param  [Array] paths The paths to select.
  # @return [Query] The query with the altered select list.
  selectPreservingImpliedConstraints: (paths = []) ->
    toRun = @clone()
    toRun.select paths

    for n in @getViewNodes() when not @isOuterJoined n
      if not (toRun.isInView n or toRun.isConstrained n) and n.getEndClass().fields.id?
        toRun.addConstraint [n.append('id'), 'IS NOT NULL']

    return toRun

  # Get a clone of this query that can be used for list operations.
  #
  # A suitable query will have a single item in its select list, and that will refer to
  # an object id. The cloned query is guaranteed to not include elements that would otherwise
  # be excluded by implied inner joins on deleted view paths.
  #
  # @return [Query] The valid list query.
  makeListQuery: ->
    paths = @views.slice()
    if paths.length != 1 or !paths[0]?.match(/\.id$/)
      paths = ['id']
    @selectPreservingImpliedConstraints paths

  saveAsList: (options, cb) ->
    toRun = @makeListQuery()
    req = utils.copy options
    req.listName = (req.listName or req.name)
    req.query = toRun.toXML()
    if (options.tags)
      req.tags = options.tags.join(';')
    withCB cb, @service.post('query/tolist', req).then LIST_PIPE @service

  # Get a summary for a single column in the results.
  #
  # A summary consists of rows of summary information, and a statistics object, which
  # always includes a uniqueValues property, which is the number of different values in the
  # column.
  #
  # @param [String|PathInfo] path The column to summarise.
  # @param [Number] limit The maximum number of rows to return.
  # @param [Function] cont An optional callback
  #
  # @return [Promise<Array<Object>, Object>] A promise to return a summary.
  summarise: (path, limit, cont) -> @filterSummary(path, '', limit, cont)

  # Get a summary for a single column in the results.
  #
  # A summary consists of rows of summary information, and a statistics object, which
  # always includes a uniqueValues property, which is the number of different values in the
  # column.
  #
  # @param [String|PathInfo] path The column to summarise.
  # @param [Number] limit The maximum number of rows to return.
  # @param [Function] cont An optional callback
  #
  # @return [Promise<Array<Object>, Object>] A promise to return a summary.
  summarize: (args...) -> @summarise.apply(@, args)

  parseSummary = (data) ->
    isNumeric = data.results[0]?.max?
    # Ideally it would be nice to avoid this ridiculous step, but we get bigInts back.
    for r in data.results
      r.count = parseInt(r.count, 10)
    stats = uniqueValues: data.uniqueValues, filteredCount: data.filteredCount
    stats = merge stats, data.results[0] if isNumeric
    data.stats = stats
    return data

  # Get a summary for a single column in the results, filtered by a given value.
  #
  # A summary consists of rows of summary information, and a statistics object, which
  # always includes a uniqueValues property, which is the number of different values in the
  # column.
  #
  # This method also allows the caller to have the server return only items which match
  # the given filter.
  #
  # @param [String|PathInfo] path The column to summarise.
  # @param [String] term The term to filter by.
  # @param [Number] limit The maximum number of rows to return.
  # @param [Function] cont An optional callback
  #
  # @return [Promise<Array<Object>, Object>] A promise to return a summary.
  filterSummary: (path, term, limit, cont = (->)) ->
    if utils.isFunction(limit)
      [cont, limit] = [limit, null]

    path = @adjustPath(path)
    toRun = @clone()
    unless path in toRun.views
      toRun.views.push(path)
    req =
      query: toRun.toXML()
      summaryPath: path
      format: 'jsonrows'

    req.size = limit if limit
    req.filterTerm = term if term
    withCB cont, @service.post('query/results', req).then parseSummary

  # Get an unconnected, deep clone of this query.
  #
  # Any changes to the clone will not affect the original query.
  #
  # @param [Boolean] cloneEvents If true, the events for the original query
  #                              will also be cloned.
  # @return [Query] A clone of this query.
  clone: (cloneEvents) ->
    cloned = new Query(@, @service)
    cloned._callbacks ?= {}
    if cloneEvents
      for own k, v of @_callbacks
        cloned._callbacks[k] = v
      cloned.off('change:views', removeIrrelevantSortOrders, this)
    return cloned

  # Get the query for the next page of results.
  #
  # @return [Query] A query for the next logical page of results.
  next: () ->
    clone = @clone()
    if @maxRows
      clone.start = @start + @maxRows
    clone

  # Get the query for the previous page of results.
  #
  # @return [Query] A query for the previous logical page of results.
  previous: () ->
    clone = @clone()
    if @maxRows
      clone.start = @start - @maxRows
    else
      clone.start = 0
    clone

  getSortDirection: (sorted) ->
    a = @adjustPath(sorted)
    throw new Error("#{ sorted } is not in the query") unless @isInQuery(a) or @isRelevant(a)
    so = utils.find @sortOrder, ({path}) -> a is path
    so?.direction

  isOuterJoined: (path) ->
    path = @adjustPath(path)
    for jp, dir of @joins when dir is 'OUTER' and path.indexOf(jp) is 0
      return true
    return false

  getOuterJoin: (path) ->
    path = @adjustPath(path)
    joinPaths = (k for k of @joins).sort (a, b) -> b.length - a.length
    utils.find(joinPaths, (p) => @joins[p] is 'OUTER' and path.indexOf(p) is 0)

  _parse_sort_order: (input) ->
    so = input
    if typeof input is 'string'
      so = {path: input, direction: 'ASC'}
    else if utils.isArray input
      [path, direction] = input
      so = {path, direction}
    else if (not input.path?)
      [path, direction] = [k, v] for k, v of input
      so = {path, direction}

    so.path = @adjustPath(so.path)
    so.direction = so.direction.toUpperCase()
    return so

  addOrSetSortOrder: (so) ->
    so = @_parse_sort_order(so)
    currentDirection = @getSortDirection(so.path)
    if not currentDirection?
      @addSortOrder(so)
    else if currentDirection isnt so.direction
      oe = utils.find @sortOrder, ({path}) -> path is so.path
      oe.direction = so.direction
      @trigger 'change:sortorder', @sortOrder
    return @

  addSortOrder: (so) ->
    @sortOrder.push @_parse_sort_order so
    @trigger 'add:sortorder', so
    @trigger 'change:sortorder', @sortOrder

  orderBy: (oes) ->
    @sortOrder = []
    for oe in oes
      @addSortOrder @_parse_sort_order oe
    @trigger 'set:sortorder change:sortorder', @sortOrder

  addJoins: (joins) ->
    if utils.isArray(joins)
      @addJoin(j) for j in joins
    else
      (@addJoin {path: k, style: v}) for k, v of joins

  addJoin: (join) ->
    if typeof join is 'string'
      join = {path: join, style: 'OUTER'}
    return @setJoinStyle join.path, join.style

  setJoinStyle: (path, style = 'OUTER') ->
    path = @adjustPath(path)
    style = style.toUpperCase()
    unless style in Query.JOIN_STYLES
      throw new Error "Invalid join style: #{ style }"
    if @joins[path] isnt style
      @joins[path] = style
      @trigger 'change:joins', path: path, style: style
    this

  addConstraints: (constraints) ->
    @__silent__ = true
    if utils.isArray(constraints)
      @addConstraint(c) for c in constraints
    else
      for path, con of constraints then do (path, con) =>
        @addConstraint interpretConstraint path, con

    @__silent__ = false
    @trigger 'add:constraint'
    @trigger 'change:constraints'

  addConstraint: (constraint) =>
    if utils.isArray(constraint)
      constraint = interpretConArray constraint
    else
      constraint = copyCon constraint

    # Don't add switched-off constraints
    return this if constraint.switched is 'OFF'

    constraint.path = @adjustPath constraint.path
    unless constraint.type?
      try
        constraint.op = get_canonical_op constraint.op
      catch error
        throw new Error "Illegal operator: #{ constraint.op }"
    @constraints.push constraint

    if @constraintLogic? and @constraintLogic isnt ''
      # Naively add this constraint as an 'AND' filter.
      @constraintLogic = "(#{@constraintLogic}) and #{ CODES[@constraints.length] }"

    unless @__silent__
      @trigger 'add:constraint', constraint
      @trigger 'change:constraints'
    this

  getSorting: -> ("#{oe.path} #{oe.direction}" for oe in @sortOrder).join(' ')

  getConstraintXML: ->
    toSerialise = (c for c in @constraints when not c.type? or @isInQuery(c.path))
    if toSerialise.length
      concatMap(conStr) concatMap(id) partition((c) -> c.type?) toSerialise
    else
      ''

  getJoinXML: () ->
    strs = for p, s of @joins when (@isInQuery(p) and s is 'OUTER')
      "<join path=\"#{ p }\" style=\"OUTER\"/>"
    strs.join ''

  toXML: ->
    attrs =
      model: @model.name
      view: @views.join(' ')
      sortOrder: @getSorting()
      constraintLogic: @constraintLogic
    attrs.name = @name if @name?
    headAttrs = (k + '="' + v + '"' for k, v of attrs when v).join(' ')
    "<query #{headAttrs} >#{ @getJoinXML() }#{ @getConstraintXML() }</query>"

  toJSON: -> noUndefVals {
    @name, @title, @comment, @description, @constraintLogic,
    from: @root
    select: (headLess v for v in @views)
    orderBy: ({path: headLess(path), direction} for {path, direction} in @sortOrder)
    joins: (headLess path for path, style of @joins when style is 'OUTER')
    where: (conToJSON c for c in @constraints)
  }

  fetchCode: (lang, cb) ->
    req =
      query: @toXML()
      lang: lang
    withCB cb, @service.post('query/code', req).then(@service.VERIFIER).then(get 'code')

  setName: (@name) ->

  # Save a query to the server, overwriting any query of the same name.
  save: (name, cb) -> REQUIRES_VERSION @service, 16, =>
    if utils.isFunction name
      [name, cb] = [null, name]
    @setName name if name?
    req =
      type: 'PUT'
      path: 'user/queries'
      data: @toXML()
      contentType: 'application/xml'
      dataType: 'json'
    withCB cb, @service.authorise(req)
                       .then((authed) => @service.doReq authed)
                       .then((resp) -> resp.queries)

  # Store this query for the first time, avoiding name collisions.
  store: (name, cb) -> REQUIRES_VERSION @service, 16, =>
    if utils.isFunction name
      [name, cb] = [null, name]
    @setName name if name?
    updateName = (err, name) => @setName(name) unless err?
    getName = utils.compose (get @name), (get 'queries')
    req =
      type: 'POST'
      path: 'user/queries'
      data: @toXML()
      contentType: 'application/xml'
      dataType: 'json'
    withCB cb, updateName, @service.authorise(req)
                                   .then((authed) => @service.doReq authed)
                                   .then(getName)

  saveAsTemplate: (name, cb) -> REQUIRES_VERSION @service, 16, =>
    if utils.isFunction name
      [name, cb] = [null, name]
    @setName name if name?
    throw new Error("Templates must have a name") unless @name
    req =
      type: 'POST'
      path: 'templates'
      data: """<template #{ conAttrs @, ['name', 'title', 'comment'] }>#{ @toXML() }</template>"""
      contentType: 'application/xml'
      dataType: 'json'
    withCB cb, @service.authorise(req).then((authed) => @service.doReq authed)

  getCodeURI: (lang) ->
    req =
      query: @toXML()
      lang: lang
      format: 'text'
    if @service?.token?
      req.token = @service.token
    "#{@service.root}query/code?#{ toQueryString req }"

  getExportURI: (format = 'tab', options = {}) ->
    if format in Query.BIO_FORMATS
      return @["get#{format.toUpperCase()}URI"](options)
    req = merge options, query: @toXML(), format: format
    if @service?.token? # hard to tell if necessary. Include it.
      req.token = @service.token
    "#{ @service.root }query/results?#{ toQueryString req }"

  # Return true if this query will require user authentication to run
  # correctly.
  #
  # This currently means that this method returns true if the query:
  #  * Contains any LIST constraints.
  #
  # @return [Boolean] Whether this query needs authentication.
  needsAuthentication: -> utils.any @constraints, (c) -> c.op in ['NOT IN', 'IN']

  # Get a query id for referencing this query in subsequent requests.
  #
  # Note that this id represents a snapshot of the query at the time of
  # the request. Any changes to the query should require a new id to be fetched.
  #
  # Duplicate queries posted to the same service will receive the same id back. So go
  # wild*
  #
  # [* do not really go wild]
  #
  # @param [->] cb An optional callback function.
  # @return [Promise<int>] A promise to yield an id.
  fetchQID: (cb) ->
    withCB cb, @service.post('queries', query: @toXML()).then get 'id'

  addPI = (p) -> p.append('primaryIdentifier').toString()

  __bio_req: (types, n) ->
    toRun = @makeListQuery() # ensures changing the view doesn't change results

    isSuitable = (p) -> utils.any types, (t) -> p.isa t

    # Only add the maximum number of suitable nodes to the query to run
    toRun.views = utils.take(n) (addPI n for n in @getViewNodes() when isSuitable n)

    query: toRun.toXML(), format: 'text'

  _fasta_req: -> @__bio_req ["SequenceFeature", 'Protein'], 1
  _gff3_req: -> @__bio_req ['SequenceFeature']
  _bed_req: Query::_gff3_req

union = fold (xs, ys) -> xs.concat ys

Query::toString = Query::toXML

Query.ATTRIBUTE_OPS = union [Query.ATTRIBUTE_VALUE_OPS, Query.MULTIVALUE_OPS, Query.NULL_OPS]
Query.REFERENCE_OPS = union [Query.TERNARY_OPS, Query.LOOP_OPS, Query.LIST_OPS]

# Ensures the arguments are correctly handled, makes sure views are fully qualified
# and applies the export view if given.
bioUriArgs = (reqMeth, f) -> (opts = {}, cb = ->) ->
  if utils.isFunction opts
    [opts, cb] = [{}, opts]
  ensureAttr = (p) =>
    path = @getPathInfo(p)
    if path.isAttribute() then path else path.append('id')
  opts.view = (@getPathInfo(v).toString() for v in opts.view) if opts?.view?
  obj = if opts.export? then @selectPreservingImpliedConstraints(opts.export.map ensureAttr) else @
  req = merge obj[reqMeth](), opts
  f.call obj, req, cb

for f in Query.BIO_FORMATS then do (f) ->
  reqMeth = "_#{ f }_req"
  getMeth = "get#{ f.toUpperCase() }"
  uriMeth = getMeth + "URI"
  Query::[getMeth] = bioUriArgs reqMeth, (req, cb) ->
    withCB cb, @service.post 'query/results/' + f, req
  Query::[uriMeth] = bioUriArgs reqMeth, (req, cb) ->
    if @service.token? # hard to tell if necessary. Include it.
      req.token = @service.token
    "#{ @service.root }query/results/#{ f }?#{ toQueryString req }"

_get_data_fetcher = (server_fn) -> (page, cbs...) ->
  if @service[server_fn]
    if not page?
      page = {}
    else if utils.isFunction page
      page = {}
      cbs = (x for x in arguments)
    page = noUndefVals merge {start: @start, size: @maxRows}, page
    return @service[server_fn](@, page, cbs...)
  else
    throw new Error("Service does not provide '#{ server_fn }'.")

for mth in RESULTS_METHODS
  Query.prototype[mth] = _get_data_fetcher mth

intermine.Query = Query
