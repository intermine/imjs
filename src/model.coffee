# This module supplies the **Model** class for the **im.js**
# web-service client.
#
# Models are representations of the descriptions of the data
# available within an intermine application.
#
# This library is designed to be compatible with both node.js
# and browsers.

IS_NODE = typeof exports isnt 'undefined'

__root__ = exports ? this

if IS_NODE
    intermine       = __root__
    {_}             = require 'underscore'
    {Deferred}  = $ = require 'underscore.deferred'
    {Table}         = require './table'
    {PathInfo}      = require './path'
    {omap}          = require('./util')
else
    {_} = __root__
    {Deferred} = $  = __root__.jQuery
    intermine       = (__root__.intermine ?= {})
    {Table, PathInfo} = intermine
    {omap}          = intermine.funcutils

# Either mocha or should is breaking the reference to _
{flatten, intersection} = _

# Lift classes to Tables
liftToTable = omap (k, v) -> [k, new Table(v)]

class Model

    constructor: ({@name, classes}) ->
        @classes = liftToTable classes

    getPathInfo: (path, subcls) -> PathInfo.parse @, path, subcls

    # Get a list that contains all the names of the
    # subclasses of this class, as well as itself.
    getSubclassesOf: (cls) ->
        clazz = if (cls and cls.name) then cls else @classes[cls]
        unless clazz?
            throw new Error("#{ cls } is not a table")
        ret = [clazz.name]
        for _, cd of @classes
            if clazz.name in cd.parents()
                ret = ret.concat(@getSubclassesOf cd)
        return ret

    # Get the list of classes that the given class descends from.
    # The list does not include the class itself.
    getAncestorsOf: (cls) ->
        clazz = if (cls and cls.name) then cls else @classes[cls]
        unless clazz?
            throw new Error("#{ cls } is not a table")
        ancestors = clazz.parents()
        for superC in ancestors
            ancestors.push @getAncestorsOf superC
        flatten ancestors

    findSharedAncestor: (classA, classB) =>
        if classB is null or classA is null
            return null
        if classA is classB
            return classA
        a_ancestry = @getAncestorsOf classA
        b_ancestry = @getAncestorsOf classB
        if classB in a_ancestry
            return classB
        if classA in b_ancestry
            return classA
        return intersection(a_ancestry, b_ancestry).shift()

    findCommonType: (xs) -> xs.reduce @findSharedAncestor

Model::makePath = Model::getPathInfo
Model::findCommonTypeOfMultipleClasses = Model::findCommonType # API preserving alias.

# Static constructor.
Model.load = (data) -> new Model(data)

Model.INTEGRAL_TYPES = ["int", "Integer", "long", "Long"]
Model.FRACTIONAL_TYPES = ["double", "Double", "float", "Float"]
Model.NUMERIC_TYPES = Model.INTEGRAL_TYPES.concat Model.FRACTIONAL_TYPES
Model.BOOLEAN_TYPES = ["boolean", "Boolean"]

intermine.Model = Model

