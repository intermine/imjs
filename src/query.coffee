# This module supplies the **Query** class for the **im.js**
# web-service client.
#
# Queries are representations of requests for data to a web-service.
# They abstract the path-query object interface which is exposed
# by the InterMine API.
#
# This library is designed to be compatible with both node.js
# and browsers.

root = exports ? this
if typeof exports is 'undefined'
    IS_NODE = false
    _ = root._
    {partition, fold, take, concatMap, id, get} = root.intermine.funcutils
    {Deferred} = $ = root.jQuery
    _CLONE = (o) -> root.jQuery.extend true, {}, o
    toQueryString = (req) -> root.jQuery.param(req)
    if typeof root.console is 'undefined'
        root.console =
            log: ->
            error: ->
    if root.intermine is 'undefined'
        root.intermine = {}
    root = root.intermine
else
    IS_NODE = true
    _               = require('underscore')._
    {Deferred}  = $ = require('underscore.deferred')
    _CLONE          = require('clone')
    toQueryString   = require('querystring').stringify
    {partition, fold, take, concatMap, id, get} = require('./shiv')

get_canonical_op = (orig) ->
    canonical = if _.isString(orig) then Query.OP_DICT[orig.toLowerCase()] else null
    unless canonical
        throw "Illegal constraint operator: #{ orig }"
    canonical

decapitate = (x) -> x.substr(x.indexOf('.'))

getListResponseHandler = (service, cb) -> (data) ->
    cb ?= ->
    name = data.listName
    service.fetchLists (ls) ->
        theList = _.find ls, (l) -> l.name is name
        cb(theList)

# Constraint XML machinery
conValStr = (v) -> "<value>#{_.escape v}</value>"
conAttrs = (c, names) -> ("""#{k}="#{_.escape(v)}" """ for k, v of c when (k in names)).join('')
noValueConStr = (c) -> """<constraint #{ conAttrs(c, ['path', 'op', 'code']) }/>"""
typeConStr = (c) -> """<constraint #{ conAttrs(c, ['path', 'type']) }/>"""
simpleConStr = (c) -> """<constraint #{ conAttrs(c, ['path', 'op', 'code', 'value', 'extraValue']) }/>"""
multiConStr = (c)  -> """<constraint #{ conAttrs(c, ['path', 'op', 'code']) }>#{concatMap(conValStr) c.values}</constraint>"""
idConStr = (c)     -> """<constraint #{ conAttrs(c, ['path', 'op', 'code']) }ids="#{c.ids.join(',')}"/>"""
conStr = (c) -> if c.values?
        multiConStr(c)
    else if c.ids?
        idConStr(c)
    else if !c.op?
        typeConStr(c)
    else if c.op in Query.NULL_OPS
        noValueConStr(c)
    else
        simpleConStr(c)

LIST_PIPE = (service) -> _.compose service.fetchList, get 'listName'

CODES = [
    null, 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
]
       

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
        "CONTAINS": "CONTAINS"
        "like": "LIKE"
        "LIKE": "LIKE"
        "not like": "NOT LIKE"
        "NOT LIKE": "NOT LIKE"
        "lookup": "LOOKUP"
        "IS NULL": "IS NULL"
        "is null": "IS NULL"
        "IS NOT NULL": "IS NOT NULL"
        "is not null": "IS NOT NULL"
        "ONE OF": "ONE OF"
        "one of": "ONE OF"
        "NONE OF": "NONE OF"
        "none of": "NONE OF"
        "in": "IN"
        "not in": "NOT IN"
        "IN": "IN"
        "NOT IN": "NOT IN"
        "WITHIN": "WITHIN"
        "within": "WITHIN"
        "OVERLAPS": "OVERLAPS"
        "overlaps": "OVERLAPS"
        "ISA": "ISA"
        "isa": "ISA"

    getPaths = ->

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
            args = if node.event then [node.event].concat(rest) else rest
            while ((node = node.next) isnt tail)
                node.callback.apply(node.context || this, args)

        this

    constructor: (properties, service) ->
        _.defaults @,
            constraints: []
            views: []
            joins: {}
            constraintLogic: ""
            sortOrder: ""
        properties ?= {}
        @displayNames = properties.aliases ? {}
    
        @service = service ? {}
        @model = properties.model ? {}
        @summaryFields = properties.summaryFields ? {}
        @root = properties.root ? properties.from
        @maxRows = properties.size ? properties.limit ? properties.maxRows
        @start = properties.start ? properties.offset ? 0

        @select(properties.views or properties.view or properties.select or [])
        @addConstraints(properties.constraints or properties.where or [])
        @addJoins(properties.joins or properties.join or [])
        @orderBy(properties.sortOrder or properties.orderBy or [])

        @constraintLogic = properties.constraintLogic if properties.constraintLogic?

        # Define private method.
        getPaths = (root, depth) =>
            cd = @getPathInfo(root).getEndClass()
            ret = [root]
            others = unless ( cd and depth > 0 ) then [] else
                _.flatten _.map cd.fields, (r) =>
                    getPaths "#{root}.#{r.name}", depth - 1

            _.flatten ret.concat others

    removeFromSelect: (unwanted) ->
        unwanted = if _.isString(unwanted) then [unwanted] else (unwanted || [])
        mapFn = _.compose(@expandStar, @adjustPath)
        unwanted = _.flatten (mapFn uw for uw in unwanted)
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
            throw "Did not remove a single constraint. original = #{ orig }, reduced = #{ reduced }"

        @constraints = reduced
        unless silent
            @trigger 'change:constraints'
            @trigger 'removed:constraints', _.difference(orig, reduced)

    addToSelect: (views) ->
        views = if _.isString(views) then [views] else ( views || [] )
        toAdd = _.map views, _.compose(@expandStar, @adjustPath)
        @views.push(p) for p in _.flatten([toAdd])
        @trigger('add:view change:views', toAdd)
    
    select: (views) ->
        @views = []
        @addToSelect views
        @

    adjustPath: (path) =>
        path = if (path && path.name) then path.name else "" + path
        if @root?
            path = @root + "." + path unless path.match "^" + @root
        else
            @root = path.split('.')[0]
        path


    getPossiblePaths: (depth = 3) ->
        @_possiblePaths ?= {}
        @_possiblePaths[depth] ?= getPaths @root, depth

    getPathInfo: (path) ->
        adjusted = @adjustPath path
        pi = @model?.getPathInfo?(adjusted, @getSubclasses())
        pi.displayName = @displayNames[adjusted] if (pi and adjusted of @displayNames)
        return pi

    getSubclasses: () ->
        fold({}, ((a, c) -> a[c.path] = c.type if c.type?;a)) @constraints

    getType: (path) ->
        @getPathInfo(path).getType()

    getViewNodes: (path) ->
        toParentNode = (v) => @getPathInfo(v).getParent()
        _.uniq(_.map(@views, toParentNode), false, (n) -> n.toPathString())

    canHaveMultipleValues: (path) -> @getPathInfo(path).containsCollection()

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
                    return (fn n for n in @summaryFields[cd.name] when (not @hasView(n)))
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
            throw new Error("This query has no service with count functionality attached.")

    # TODO: unit tests
    appendToList: (target, cb) ->
        name = if (target && target.name) then target.name else '' + target
        toRun = @clone()
        if toRun.views.length isnt 1 || !toRun.views[0].match(/\.id$/)
            toRun.select(['id'])
        req =
            listName: name
            query: toRun.toXML()
        updateTarget = if (target?.name) then ((list) -> target.size = list.size) else (->)

        @service.post('query/append/tolist', req).pipe(LIST_PIPE @service).done(cb, updateTarget)

    saveAsList: (options, cb) ->
        toRun = @clone()
        if toRun.views.length != 1 || toRun.views[0] is null || !toRun.views[0].match(/\.id$/)
            toRun.select(['id'])

        req = _.clone(options)
        req.listName = req.listName || req.name
        req.query = toRun.toXML()
        if (options.tags)
            req.tags = options.tags.join(';')
        @service.post('query/tolist', req).pipe(LIST_PIPE @service).done(cb)

    summarise: (path, limit, cont) -> @filterSummary(path, '', limit, cont)

    summarize: (args...) -> @summarise.apply(@, args)

    filterSummary: (path, term, limit, cont = (->)) ->
        if _.isFunction(limit)
            [cont, limit] = [limit, null]

        path = @adjustPath(path)
        toRun = @clone()
        unless _.include(toRun.views, path)
            toRun.views.push(path)
        req =
            query: toRun.toXML()
            summaryPath: path
            format: 'jsonrows'

        req.size = limit if limit
        req.filterTerm = term if term
        parse = (data) -> Deferred -> @resolve data.results, data.uniqueValues, data.filteredCount
        @service.post('query/results', req).pipe(parse).done(cont)

    clone: (cloneEvents) ->
        cloned = _CLONE(@)
        if cloneEvents
            cloned._callbacks = @._callbacks
        else
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

    getOuterJoin: (path) ->
        path = @adjustPath(path)
        joinPaths = _.sortBy(_.keys(@joins), get 'length').reverse()
        _.find(joinPaths, (p) => @joins[p] is 'OUTER' and path.indexOf(p) is 0)

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
        if _.isArray(joins)
            @addJoin(j) for j in joins
        else
            (@addJoin {path: k, style: v}) for k, v of joins

    addJoin: (join) ->
        if _.isString(join)
            join = {path: join, style: 'OUTER'}
        join.path = @adjustPath(join.path)
        join.style = join.style?.toUpperCase() ? join.style
        unless join.style in Query.JOIN_STYLES
            throw "Invalid join style: #{ join.style }"
        @joins[join.path] = join.style
        @trigger 'set:join', join.path, join.style
        
    setJoinStyle: (path, style = 'OUTER') ->
        path = @adjustPath(path)
        style = style.toUpperCase()
        if @joins[path] isnt style
            @joins[path] = style
            @trigger 'change:joins', path: path, style: style
        this

    addConstraints: (constraints) ->
        @__silent__ = true
        if _.isArray(constraints)
            @addConstraint(c) for c in constraints
        else
            for path, con of constraints then do (path, con) =>
                constraint = {path}
                if con is null
                    constraint.op = 'IS NULL'
                else if _.isArray(con)
                    constraint.op = 'ONE OF'
                    constraint.values = con
                else if _.isString(con) or _.isNumber(con)
                    if con.toUpperCase?() in Query.NULL_OPS
                        constraint.op = con
                    else
                        constraint.op = '='
                        constraint.value = con
                else
                    keys = (k for k, x of con)
                    if 'isa' in keys
                        if _.isArray(con.isa)
                            constraint.op = k
                            constraint.values = con.isa
                        else
                            constraint.type = con.isa
                    else
                        if 'extraValue' in keys
                            constraint.extraValue = con.extraValue
                        for k, v of con when (k isnt 'extraValue')
                            constraint.op = k
                            if _.isArray(v)
                                constraint.values = v
                            else
                                constraint.value = v
                @addConstraint(constraint)

        @__silent__ = false
        @trigger 'add:constraint'
        @trigger 'change:constraints'

    addConstraint: (constraint) ->
        if _.isArray(constraint)
            conArgs = constraint.slice()
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
                if _.isArray(v)
                    constraint.values = v
                else
                    constraint.value = v
                if conArgs.length == 3
                    constraint.extraValue = conArgs[2]
        constraint.path = @adjustPath(constraint.path)
        unless constraint.type?
            try
                constraint.op = get_canonical_op(constraint.op)
            catch error
                throw new Error("Illegal operator: #{ constraint.op }")
        @constraints.push constraint

        if @constraintLogic? and @constraintLogic isnt '' # Naively add this constraint as an 'AND' filter.
            @constraintLogic = "(#{@constraintLogic}) and #{ CODES[@constraints.length] }"

        unless @__silent__
            @trigger 'add:constraint', constraint
            @trigger 'change:constraints'
        this

    getSorting: () ->
        @sortOrder.map((oe) -> "#{oe.path} #{oe.direction}").join(' ')

    getConstraintXML: () ->
        if @constraints.length
            concatMap(conStr) concatMap(id) partition((c) -> c.type?) @constraints
        else
            ''

    getJoinXML: () ->
        strs = for p, s of @joins when (@isRelevant(p) and s is 'OUTER')
            "<join path=\"#{ p }\" style=\"OUTER\"/>"
        strs.join ''

    toXML: () ->
        attrs =
            model: @model.name
            view: @views.join(' ')
            sortOrder: @getSorting()
            constraintLogic: @constraintLogic
        attrs.name = @name if @name?
        headAttrs = (k + '="' + v + '"' for k, v of attrs when v).join(' ')
        "<query #{headAttrs} >#{ @getJoinXML() }#{ @getConstraintXML() }</query>"

    isRelevant: (p) ->
        pi = @getPathInfo p
        if pi
            pstr = pi.toPathString()
            _.any _.union(@views, _.pluck(@constraints, 'path')), (p) ->
                p.indexOf(pstr) is 0
        else
            true # No model available - for testing return true.

    fetchCode: (lang, cb) ->
        req =
            query: @toXML()
            lang: lang
        @service.get('query/code', req).pipe(@service.VERIFIER).pipe(get 'code').done(cb)

    # Save a query to the server, with the name given.
    save: (name, cb) ->
        @name = name if name?
        req =
            data: @toXML()
            contentType: "application/xml; charset=UTF-8"
            url: @service.root + 'query'
            type: 'POST'
            dataType: 'json'
        @service.doReq(req)
            .pipe(@service.VERIFIER)
            .pipe(get 'name')
            .done(cb, (name) => @name = name)

    # TODO: saveAsTemplate()

    getCodeURI: (lang) ->
        req =
            query: @toXML()
            lang: lang
            format: 'text'
        if @service?.token?
            req.token = @service.token
        "#{@service.root}query/code?#{ toQueryString req }"

    getExportURI: (format = 'tab') ->
        if format in Query.BIO_FORMATS
            return @["get#{format.toUpperCase()}URI"]()
        req =
            query: @toXML()
            format: format
        if @service?.token? # hard to tell if necessary. Include it.
            req.token = @service.token
        "#{ @service.root }query/results?#{ toQueryString req }"

    __bio_req: (types, n) ->
        toRun = @clone()
        olds = toRun.views
        toRun.views = take(n) (olds.map((v) => @getPathInfo(v).getParent())
            .filter((p) -> _.any types, (t) -> p.isa(t))
            .map((p) -> p.append('primaryIdentifier').toPathString()))

        query: toRun.toXML(), format: 'text'

    _fasta_req: () -> @__bio_req ["SequenceFeature", 'Protein'], 1
    _gff3_req: () -> @__bio_req ['SequenceFeature']
    _bed_req: Query::_gff3_req

Query.ATTRIBUTE_OPS = _.union Query.ATTRIBUTE_VALUE_OPS, Query.MULTIVALUE_OPS, Query.NULL_OPS
Query.REFERENCE_OPS = _.union Query.TERNARY_OPS, Query.LOOP_OPS, Query.LIST_OPS

for f in Query.BIO_FORMATS then do (f) ->
    reqMeth = "_#{ f }_req"
    getMeth = "get#{ f.toUpperCase() }"
    uriMeth = getMeth + "URI"
    Query.prototype[getMeth] = (cb = ->) ->
        req = @[reqMeth]()
        @service.post('query/results/' + f, req).done cb
    Query.prototype[uriMeth] = (cb) ->
        req = @[reqMeth]()
        if @service?.token? # hard to tell if necessary. Include it.
            req.token = @service.token
        "#{ @service.root }query/results/#{ f }?#{ toQueryString req }"

_get_data_fetcher = (server_fn) -> (page, cb) ->
    cb ?= page
    page = if (_.isFunction(page) or not page) then {} else page
    if @service[server_fn]
        _.defaults page, {start: @start, size: @maxRows}
        return @service[server_fn](@, page, cb)
    else
        throw new Error("Could not find #{ server_fn } at this service. Sorry.")

for mth in ['rowByRow', 'eachRow', 'recordByRecord', 'eachRecord', 'records', 'rows', 'table', 'tableRows']
    Query.prototype[mth] = _get_data_fetcher mth

root.Query = Query
