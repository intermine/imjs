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

# Import from the appropriate place depending on whether we are in
# node.js or in the browser.
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

# A representation of the metadata for an InterMine. This class
# allows the user to inspect what kinds of data a mine is configured
# with, allowing us to verify existing queries, as well as constructing
# queries automatically by walking the data-model.
class Model

    # Constructor.
    #
    # @param options The data used to construct this model.
    # @option options [String] name The name of this model.
    # @option options [Object<String, Object>] classes A description of the classes.
    constructor: ({@name, classes}) ->
        @classes = liftToTable classes

    # Construct a PathInfo object representing the given path, given the
    # specified subclass constraints.
    # @param [#toString] path The path to represent.
    # @param [Object<String, String>] subcls The subclass constraints. (optional)
    # @return [PathInfo] A representation of the path.
    getPathInfo: (path, subcls) => PathInfo.parse @, path, subcls

    # Get a list that contains all the names of the
    # subclasses of this class, as well as itself.
    # For an inheritance pattern such as:
    #
    #        A        B   C
    #        |         \ /
    #        D   E  F   G
    #         \ /    \ / \
    #          |      |   \
    #          H      I    J
    #            \  /  \   |
    #             K     L  M
    #
    # The subclasses of B will be [B, G, I, K, L, J, M] or [B, G, J, M, I, K, L],
    # depending on the order in which the classes are iterated over.
    #
    # @param [String|Table] cls The class to get subclasses of.
    # @return [Array<String>] The names of this class and all its subclasses.
    getSubclassesOf: (cls) =>
        clazz = if (cls and cls.name) then cls else @classes[cls]
        unless clazz?
            throw new Error("#{ cls } is not a table")
        ret = [clazz.name]
        for _, cd of @classes
            if clazz.name in cd.parents()
                ret = ret.concat(@getSubclassesOf cd)
        return ret

    # Get the list of classes that the given class descends from.
    # The list does not include the class itself. For an inheritance pattern such as:
    #
    #        A        B   C
    #        |         \ /
    #        D   E  F   G
    #         \ /    \ / \
    #          |      |   \
    #          H      I    J
    #            \  /  \   |
    #             K     L  M
    #
    # The list of ancestors of J will be [H, I, D, E, A, F, G, B, C]
    #
    # @param [String|Table] cls The class whose ancestry is to be retrieved.
    # @return [Array<String>] A list of names of classes this class inherits from.
    getAncestorsOf: (cls) =>
        clazz = if (cls and cls.name) then cls else @classes[cls]
        unless clazz?
            throw new Error("#{ cls } is not a table")
        ancestors = clazz.parents()
        for superC in ancestors
            ancestors.push @getAncestorsOf superC
        flatten ancestors

    # Get the closest shared ancestor of these two classes.
    # For an inheritance pattern such as:
    #
    #        A        B   C
    #        |         \ /
    #        D   E  F   G
    #         \ /    \ / \
    #          |      |   \
    #          H      I    J
    #            \  /  \   |
    #             K     L  M
    #
    # The closest shared ancestor of K and M is G, while the closest shared
    # ancestor of K and L is I. The closest shared ancestor of H and I is null.
    #
    # @param [String|Table] classA The first class
    # @param [String|Table] classB The second class
    # @return [String] The name of the closest shared ancestor
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

    # Find the common type of a list of classes or class names, or null if there is no
    # one common type.
    # @param [Array<String|Table>] xs the classes.
    # @return [String] The name of the common superclass, or null.
    findCommonType: (xs = []) => xs.reduce @findSharedAncestor

Model::makePath = Model::getPathInfo
Model::findCommonTypeOfMultipleClasses = Model::findCommonType # API preserving alias.

# Static constructor.
Model.load = (data) -> new Model(data)

Model.INTEGRAL_TYPES = ["int", "Integer", "long", "Long"]
Model.FRACTIONAL_TYPES = ["double", "Double", "float", "Float"]
Model.NUMERIC_TYPES = Model.INTEGRAL_TYPES.concat Model.FRACTIONAL_TYPES
Model.BOOLEAN_TYPES = ["boolean", "Boolean"]

intermine.Model = Model

