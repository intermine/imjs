unless Array::map?
    Array::map = (f) -> (f x for x in @)

unless Array::filter?
    Array::filter = (f) -> (x for x in @ when (f x))

unless Array::reduce?
    Array::reduce = (f, initValue) ->
        xs = @slice()
        ret = initValue ? xs.pop()
        ret = (f ret, x) for x in xs
        ret

# Export functions defined here either onto the
# exports object (if we are in node) or onto the global
# intermine.funcutils namespace
root = exports ? this
unless exports?
    root.intermine ?= {}
    root.intermine.funcutils ?= {}
    root = root.intermine.funcutils

root.fold = (init, f) -> (xs) ->
    if xs.reduce? # arrays
        xs.reduce f, init
    else # objects
        ret = init
        for k, v of xs
           ret = if ret? then f(ret, k, v) else {k: v}
        ret

root.take = (n) -> (xs) -> if n? then xs[0 .. n - 1] else xs

# Until I can find a nicer name for this...
# Basically a mapping over an object, taking a
# function of the form (oldk, oldv) -> [newk, newv]
root.omap = (f) -> (o) ->
    domap = exports.fold {}, (a, k, v) ->
        [kk, vv] = f k, v
        a[kk] = vv
        a
    domap o

root.partition = (f) -> (xs) ->
    trues = []
    falses = []
    for x in xs
        if f x
            trues.push x
        else
            falses.push x
    [trues, falses]

# Implementation of concatmap.
#
# This a function that applies a function to each member
# of an array, and combines the results through the natural
# method of combination. Arrays are concatenated, and strings
# are, well, concatenated. Objects are merged.
#
# @param f The function to apply to each item.
# @param xs The things to apply them to.
root.concatMap = (f) -> (xs) ->
    ret = undefined
    for x in xs
        fx = f x
        ret = if ret is undefined
            fx
        else if typeof fx is 'string'
            ret + fx
        else if fx.slice?
            ret.concat(fx)
        else
            ret[k] = v for k, v of fx
            ret
    ret

root.AND = (a, b) -> a and b

root.OR = (a, b) -> a or b

root.NOT = (x) -> not x

# The identity function
#
# @param x Something
# @return The self same thing.
root.id = (x) -> x

# A set of functions that are helpful when dealing with promises,
# in that they help produce the kinds of simple pipes that are
# frequently used as callbacks.

# Get a function that invokes a named method
# on an object of type A.
# 
# @param [String] name The name of a method
# @param [Array] args An optional argument list, passed as varargs
# @return [(obj) -> ?] A function that invokes a named method.
root.invoke = (name, args...) -> (obj) -> obj[name].apply(obj, args)

# Get a function that invokes a method on an object
# that is passed to it with the arguments given here, with
# an optional binding for this.
#
# This function differs from invoke in that it expects the optional
# argument list to be passed in an Array, rather than as separate
# elements in the argument list.
#
# @param [String] name The name of the method
# @param [Array] args The arguments to the method
# @param [Object] ctx The value for this in the invocation (optional)
# @return [(obj) -> ?] A function that invokes a named method.
root.invokeWith = (name, args = [], ctx = null) -> (o) -> o[name].apply((ctx or o), args)

# Get a function that gets a named property off an object.
#
# @param [String] name the name of the property
# @return [(obj) -> ?] A function that gets a property's value.
root.get = (name) -> (obj) -> obj[name]

# Get a function that sets a named property, or set of properties
# on an object, returning the new state of the object.
#
# @example
#   promise.then(set('name', 'Anne'))
#   promise.then(set({name: 'Bill', age: 43}))
#
# @param [String|Object] name the name of the property, or an object of
#   properties to set.
# @param [?] value The value to set (optional).
# @return [(obj) -> ?] A function that sets a property's value, and returns the object.
root.set = (name, value) -> (obj) ->
    if arguments.length is 2
        obj[name] = value
    else
        for own k, v of name
            obj[k] = v
    return obj

