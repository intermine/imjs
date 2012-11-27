# This module supplies the **PathInfo** class for the **im.js**
# web-service client.
#
# Paths are representations of elements within a query, such as
# an element in the select list or something with a constraint on it.
# They consiste of a root class, zero or more references, and an optional
# final attribute.
#
# This library is designed to be compatible with both node.js
# and browsers.

IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

if IS_NODE
    intermine       = __root__
    {_}             = require 'underscore'
    {Deferred}  = $ = require 'underscore.deferred'
    utils           = require('./util')
else
    {_}            = __root__
    {Deferred} = $ = __root__.jQuery
    intermine      = __root__.intermine
    utils          = intermine.funcutils

{concatMap, get, any, set, copy, success, error} = utils

NAMES = {}
PARSED = {}

makeKey = (model, path, subclasses) ->
    """#{model?.name}|#{model?.service?.root}|#{path}:#{ "#{ k }=#{ v }" for k, v of subclasses }"""

#
# A representation of the information contained in a path
# expression. This class exposes the metadata available for this
# path, and is aware of class constraints placed upon it.
#
class PathInfo

    constructor: ({ @root, @model, @descriptors, @subclasses, @displayName, @ident}) ->
        @end = _.last @descriptors
        @ident ?= makeKey(@model, @, @subclasses)

    isRoot: () => @descriptors.length is 0

    isAttribute: () => @end? and not @end.referencedType?

    isClass: () => @isRoot() or @end.referencedType?

    isReference: () => @end?.referencedType?

    isCollection: () => @end?.isCollection ? false

    containsCollection: () => any @descriptors, (x) -> x.isCollection

    getEndClass: () => (@model.classes[@subclasses[@toString()] or @end?.referencedType]) or @root

    getParent: () =>
        if @isRoot()
            throw new Error("Root paths do not have parents")
        data =
            root: @root
            model: @model
            descriptors: _.initial(@descriptors)
            subclasses: @subclasses
        return new PathInfo(data)

    append: (attr) =>
        if @isAttribute()
            throw new Error("#{ @ } is an attribute.")
        fld = if (_.isString attr) then @getType().fields[attr] else attr
        unless fld?
            throw new Error("#{ attr } is not a field of #{ @getType() }")
        data =
            root: @root
            model: @model
            descriptors: @descriptors.concat(fld)
            subclasses: @subclasses
        return new PathInfo(data)

    isa: (clazz) =>
        if @isAttribute()
            @getType() is clazz
        else
            name = if (clazz.name) then clazz.name else '' + clazz
            type = @getType()
            (name is type.name) or (name in @model.getAncestorsOf(type))

    getDisplayName: (cb) =>
        @namePromise ?=
            if cached = (@displayName or NAMES[@ident])
                success cached
            else if not @model.service?
                error "No service"
            else
                path = 'model' + (concatMap (d) -> '/' + d.name) @allDescriptors()
                params = (set format: 'json') copy @subclasses
                @model.service.get(path, params).then(get 'display').done (n) => NAMES[@ident] ?= n
        @namePromise.done(cb)

    getChildNodes: () => (@append(fld) for _, fld of (@getEndClass()?.fields or {}))

    allDescriptors: => [@root].concat(@descriptors)

    toString: () -> @allDescriptors().map(get 'name').join('.')

    #
    # Get the type of a path. If the path represents a class or a reference,
    # the class itself is returned, otherwise the name of the attribute type is returned,
    # minus any "java.lang." prefix.
    #
    # @param path The path to get the type of
    # @return A class-descriptor, or an attribute type name.
    #
    getType: () -> (@end?.type?.replace /java\.lang\./, '') or @getEndClass()

PathInfo::toPathString = PathInfo::toString

PathInfo.parse = (model, path, subclasses = {}) ->
    ident = makeKey(model, path, subclasses)
    if cached = PARSED[ident]
        return cached
    parts       = path.split '.'
    root  = cd  = model.classes[parts.shift()]
    keyPath     = root.name
    descriptors = for part in parts
        fld = cd?.fields[part] or (cd = model.classes[subclasses[keyPath]])?.fields[part]
        unless fld
            throw new Error("Could not find #{ part } in #{ cd } when parsing #{ path }")
        keyPath += ".#{ part }"
        cd = model.classes[fld.type || fld.referencedType]
        fld
    PARSED[ident] = new PathInfo({root, model, descriptors, subclasses, ident})

PathInfo.flushCache = () ->
    PARSED = {}
    NAMES = {}

intermine.PathInfo = PathInfo
