if typeof exports is 'undefined'
    IS_NODE = false
    exports = this
    _ = exports._
    clone = (o) -> jQuery.extend true, {}, o
    toQueryString = (req) -> jQuery.param(req)
    if exports.intermine is 'undefined'
        exports.intermine = {}
    exports = exports.intermine
    if typeof console is 'undefined'
        console = log: ->
else
    IS_NODE = true
    _ = require('underscore')._
    clone = require('clone')
    toQueryString = require('querystring').stringify

get_canonical_op = (orig) ->
    canonical = _.isString(orig) ? OP_DICT[orig.toLowerCase()] : null
    unless canonical
        throw "Illegal constraint operator: #{ orig }"
    canonical

decapitate = (x) -> x.substr(x.indexOf('.'))

getListResponseHandler = (service, cb) -> (data) ->
    cb ?= ->
    name = data.listName
    @service.fetchLists (ls) -> cb(_.find(ls, (l) -> l.name is name))

class Query
    @JOIN_STYLES = ['INNER', 'OUTER']
    @NULL_OPS = ['IS NULL', 'IS NOT NULL']
    @OP_DICT =
        "=" : "="
        "==": "="
        "eq": "="
        "!=": "!="
        "ne": "!="
        ">" : ">"
        "gt" : ">"
        ">=": ">="
        "ge": ">="
        "<": "<"
        "lt": "<"
        "<=": "<="
        "le": "<="
        "contains": "CONTAINS"
        "like": "LIKE"
        "lookup": "LOOKUP"
        "IS NULL": "IS NULL"
        "is null": "IS NULL"
        "IS NOT NULL": "IS NOT NULL"
        "is not null": "IS NOT NULL"
        "ONE OF": "ONE OF"
        "one of": "ONE OF"
        "in": "IN"
        "not in": "IN"
        "IN": "IN"
        "NOT IN": "NOT IN"

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

    bind: (args...) -> @on.apply(@, args)

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
            args = node.event ? [node.event].concat(rest) : rest
            while ((node = node.next) isnt tail)
                node.callback.apply(node.context || this, args)

        this

    initialize: (properties, service) ->
        _.defaults @,
            constraints: []
            views: []
            joins: []
            constraintLogic: ""
            sortOrder: ""
    
        @service = service ? {}
        @model = properties.model ? {}
        @summaryFields = properties.summaryFields ? {}
        @root = properties.root ? properties.from
        @maxRows = properties.size ? properties.limit ? properties.maxRows
        @start = properties.start ? properties.offset ? 0

        @select(properties.views or properties.select or [])
        @addConstraints(properties.constraints or properties.where or [])
        @addJoins(properties.joins or properties.join or [])
        @orderBy(properties.sortOrder or properties.orderBy or [])

        @constraintLogic = properties.constraintLogic if properties.constraintLogic?

    removeFromSelect: (unwanted) ->
        unwanted = _.isString() ? [unwanted] : unwanted || []
        mapFn = _.compose(@expandStar, @adjustPath)
        unwanted = _.flatten (mapFn uw for uw in unwanted)
        @sortOrder = (so for so in @sortOrder when (not _.include(unwanted, so.path)))
        @views = _.difference(@views, unwanted)
        @trigger('remove:view', unwanted)
        @trigger('change:views', @views)

    removeConstraint: (con) ->
        orig = @constraints
        iscon = if typeof con is 'string'
            (c) -> c.code is con
        else
            (c) ->
                ( (c.path is con.path) and (c.op is con.op) and (c.value is con.value)
                  and (c.extraValue is con.extraValue) and (con.type is c.type)
                  and (c.values?.join('%%') is con.values?.join('%%')) )

        reduced = (c for c in orig when (not iscon c))

        if reduced.length isnt orig.length - 1
            throw "Did not remove a single constraint. original = #{ orig }, reduced = #{ reduced }"

        @constraints = reduced
        @trigger 'change:constraints'
        @trigger 'removed:constraints', _.difference(orig, reduced)

    addToSelect: (views) ->
        views = _.isString(views) ? [views] : views || []
        toAdd = _.map views, _.compose(@expandStar, @adjustPath)
        @views.push(p) for p in _.flatten([toAdd])
        @trigger 'add:view change:views', toAdd
    
    select: (views) ->
        @views = []
        @addToSelect(v) for v in views
        @

    # necessary now?
    _getAllFields: (table) ->
        attrs = _.values(table.attributes)
        refs = _.values(table.references)
        cols = _.values(table.collections)
        _.union(attrs, refs, cols)

    _getPaths: (root, cd, depth) ->
        self = @
        ret = [root]
        others = []
        if cd and depth > 0
            others = _.flatten(_.map(cd.fields, (r) ->
                self._getPaths(
                    "#{root}.#{r.name}",
                    self.getPathInfo("#{root}.#{r.name}").getEndClass(),
                    depth - 1)))

        ret.concat(others)

    getPossiblePaths: (depth = 3) ->
        @_possiblePaths ?= {}
        cd = @service.model.classes[@root]
        @_possiblePaths[depth] ?= _.flatten(@_getPaths(@root, cd, depth))

    getPathInfo: (path) ->
        @service.model.getPathInfo(@adjustPath(path), @getSubclasses())

    getType: (path) ->
        @getPathInfo(path).getType()

    getViewNodes: (path) ->
        toParentNode = (v) => @getPathInfo(v).getParent()
        _.uniq(_.map(@views, toParentNode), false, (n) -> n.toPathString())

    canHaveMultipleValues: (path) ->
        @service.model.hasCollection(@adjustPath(path))

    getQueryNodes: () ->
        viewNodes = @getViewNodes()
        constrainedNodes = _.map @constraints, (c) =>
            pi = @getPathInfo(c.path)
            if pi.isAttribute() then pi.getParent() else pi
        _.uniq viewNodes.concat(constrainedNodes), false, (n) -> n.toPathString()

    expandStar: (path) =>
        if /\*$/.test(path)
            pathStem = path.substr(0, path.lastIndexOf('.'))
            expand = (x) -> pathStem + x
            cd = @getType(pathStem)
            if /\.\*$/.test(path)
                if cd and @summaryFields[cd.name]
                    fn = _.compose expand, decapitate
                    return (n for n, f of @summaryFields[cd.name] when (not @hasView(n)))
            if /\.\*\*$/.test(path)
                fn = _.compose(expand, (a) -> '.' + a.name)
                return _.uniq(_.union(@expandStar(pathStem + '.*'), _.map(cd.attributes, fn)))

        return path

    isOuterJoin: (p) -> @joins[@adjustPath(p)] is 'OUTER'

    hasView: (v) -> @views && _.include(@views, @adjustPath(v))

    count: (cont) ->
        if @service.count
            @service.count(@, cont)
        else
            throw "This query has no service attached. It cannot request a count"

    # TODO: unit tests
    appendToList: (target, cb) ->
        name = (target && target.name) target.name : '' + target
        toRun = @clone()
        if toRun.views.length isnt 1 || !toRun.views[0].match(/\.id$/)
            toRun.select(['id'])
        req =
            listName: name
            query: toRun.toXML()
        cb = (target && target.name) then ((list) -> target.size = list.size; cb(list)) else cb

        return @service.makeRequest('query/append/tolist',
            req, getListResponseHandler(@service, cb), 'POST')

    saveAsList: (options, cb) ->
        toRun = @clone()
        if toRun.views.length != 1 || toRun.views[0] is null || !toRun.views[0].match(/\.id$/)
            toRun.select(['id'])

        req = _.clone(options)
        req.listName = req.listName || req.name
        req.query = toRun.toXML()
        if (options.tags)
            req.tags = options.tags.join(';')
        @service.makeRequest('query/tolist', req, getListResponseHandler(@service, cb), 'POST')

    summarise: (path, limit, cont) -> @filterSummary(path, '', limit, cont)

    summarize: (args...) -> @summarise.apply(@, args)

    filterSummary: (path, term, limit, cont) ->
        if _.isFunction(limit) && !cont
            cont = limit
            limit = null

        cont ?= ->
        path = @adjustPath(path)
        toRun = @clone()
        unless _.include(toRun.views, path)
            toRun.views.push(path)
        req =
            query: toRun.toXML()
            format: 'jsonrows'
            summaryPath: path
        req.size = limit if limit
        req.filterTerm = term if term
        @service.makeRequest('query/results', req,
            (data) -> cont(data.results, data.uniqueValues, data.filteredCount))

    clone: (cloneEvents) ->
        cloned = clone(@)
        unless cloneEvents
            cloned._callbacks = {}
        return cloned

    next: () ->
        clone = @clone()
        if @maxRows
            clone.start = @start + @maxRows
        clone

    previous: () ->
        clone = @clone()
        if @maxRows
            clone.start = @start - @maxRows
        else
            clone.start = 0
        clone

    getSortDirection: (path) ->
        path = @adjustPath(path)
        dir = so.direction for so in @sortOrder when (so.path is path)
        return dir

    isOuterJoined: (path) ->
        path = @adjustPath(path)
        _.any(@joins, (d, p) -> d is 'OUTER' and path.indexOf(p) is 0)

    _parse_sort_order: (input) ->
        so = input
        if _.isString(input)
            so = {path: input, direction: 'ASC'}
        else if (not input.path?)
            k = _.keys(input)[0]
            v = _.values(input)[0]
            so = {path: k, direction: v}

        so.path = @adjustPath(so.path)
        so.direction = so.direction.toUpperCase()
        return so

    addOrSetSortOrder: (so) ->
        so = @_parse_sort_order(so)
        currentDirection = @getSortDirection(so.path)
        if not currentDirection?
            @addSortOrder(so)
        else if currentDirection isnt so.direction
            for oe in @sortOrder when (oe.path is so.path)
                oe.direction = so.direction
            @trigger 'change:sortorder', @sortOrder

    addSortOrder: (so) ->
        @sortOrder.push @_parse_sort_order so
        @trigger 'add:sortorder', so
        @trigger 'change:sortorder', @sortOrder

    orderBy: (oes) ->
        @sortOrder = []
        for oe in oes
            @addSortOrder(oe)
        @trigger 'set:sortorder', @sortOrder

    addJoins: (joins) ->
        @addJoin(j) for j in joins

    addJoin: (join) ->
        if _.isString(join)
            join = {path: join, style: 'OUTER'}
        join.path = @adjustPath(join.path)
        join.style = join.style?.toUpperCase() ? join.style
        unless join.style in Query.JOIN_STYLES
            throw "Invalid join style: #{ join.style }"
        @joins[join.path] = join.style
        @trigger 'set:join', join.path, join.style
        








_get_data_fetcher: (server_fn) -> (page, cb) ->
    cb ?= page
    page = if (_.isFunction(page) or not page) then {} else page
    if @service[server_fn]
        _.defaults page, {start: @start, size: @maxRows}
        @service[server_fn](@, page, cb)
    else
        throw "This query has no service attached. It cannot request results"

Query::rowByRow = _get_data_fetcher('rowByRow')
Query::recordByRecord = _get_data_fetcher('recordByRecord')
Query::records = _get_data_fetcher('records')
Query::rows = _get_data_fetcher('rows')
Query::table = _get_data_fetcher('table')











    








    


