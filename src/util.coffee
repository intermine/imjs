# Export functions defined here either onto the
# exports object (if we are in node) or onto the global
# intermine.funcutils namespace

IS_NODE = typeof exports isnt 'undefined'
root = exports ? this

if IS_NODE
  {Deferred} = require 'underscore.deferred'
  {_} = require 'underscore'
else
  {Deferred} = root.jQuery
  {_} = root
  root.intermine ?= {}
  root.intermine.funcutils ?= {}
  root = root.intermine.funcutils

# Simply because this is a whole load cleaner and less ugly than
# calls to `_.bind(f, null, arg1, arg2, ...)`.
# @param [->] f The function to curry.
# @param args the arguments to curry.
# @return a curried function.
root.curry = curry = (f, args...) -> (rest...) -> f.apply(null, args.concat(rest))

# Helper for transforming an error into a rejection.
# @param e The error.
# @return [Promise<Error>] A promise to reject with an error.
root.error = (e) -> Deferred( -> @reject new Error(e) ).promise()

# Helper for wrapping a value in a promise.
# @param args the The resolution.
# @return [Promise<args...>] A promise to resolve with the resolution.
root.success = success = (args...) -> Deferred( -> @resolve args... ).promise()

root.fold = fold = (f) -> (init, xs) ->
  if arguments.length is 1
    xs = (init?.slice() or init)
    init = (xs?.shift() or {})
  throw new Error("xs is null") unless xs?
  if xs.reduce? # arrays
    xs.reduce f, init
  else # objects
    ret = init
    for k, v of xs
      ret = if ret? then f(ret, k, v) else {k: v}
    ret

root.take = (n) -> (xs) -> if n? then xs[0 .. n - 1] else xs

# Curried version of filtering
root.filter = (f) -> (xs) -> (x for x in xs when f x)

# Until I can find a nicer name for this...
# Basically a mapping over an object, taking a
# function of the form (oldk, oldv) -> [newk, newv]
root.omap = (f) ->
  merger = fold (a, oldk, oldv) ->
    [newk, newv] = f oldk, oldv
    a[newk] = newv
    return a
  (xs) -> merger {}, xs

root.copy = root.omap (k, v) -> [k, v]

root.partition = (f) -> (xs) ->
  trues = []
  falses = []
  for x in xs
    if f x
      trues.push x
    else
      falses.push x
  [trues, falses]

# The identity function
#
# @param x Something
# @return The self same thing.
root.id = id = (x) -> x

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
    else if typeof fx in ['string', 'number']
      ret + fx
    else if fx.slice?
      ret.concat(fx)
    else
      ret[k] = v for k, v of fx
      ret
  ret

root.flatMap = root.concatMap

root.sum = root.concatMap id

root.AND = (a, b) -> a and b

root.OR = (a, b) -> a or b

root.NOT = (x) -> not x

root.any = (xs, f = id) ->
  for x in xs
    return true if f x
  return false

# A set of functions that are helpful when dealing with promises,
# in that they help produce the kinds of simple pipes that are
# frequently used as callbacks.

# Get a function that invokes a named method
# on an object of type A.
#
# @param [String] name The name of a method
# @param [Array] args An optional argument list, passed as varargs
# @return [(obj) -> ?] A function that invokes a named method.
root.invoke = (name, args...) -> (obj) ->
  if obj[name]?.apply
    obj[name].apply(obj, args)
  else
    Deferred().reject("No method: #{ name }").promise()

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

root.flip = (f) -> (args...) -> f.apply(null, args.reverse())

# Make a function that lets users know
# when they are trying to use a service that
# isn't supported by their current service.
REQUIRES = (required, got) ->
  "This service requires a service at version #{ required } or above. This one is at #{ got }"

# A wrapper for functions that make requests to endpoints
# that require a certain version of the intermine API.
root.REQUIRES_VERSION = (s, n, f) -> s.fetchVersion().pipe (v) ->
  if v >= n
    f()
  else
    error REQUIRES n, v

# Helper function that makes sure a query doesn't have
# any implicit constraints through the use of inner-joins.
# All chains of references will be converted to outer-joins.
root.dejoin = (q) ->
  for view in q.views
    parts = view.split('.')
    q.addJoin(parts[1..-2].join '.') if parts.length > 2
  return q

# Sequence a series of asynchronous functions.
thenFold = fold (p, f) -> p.then f

root.sequence = (fns...) -> thenFold success(), _.flatten fns

pairFold = fold (o, [k, v]) ->
  if o[k]?
    throw new Error("Duplicate key: #{ k }")
  o[k] = v
  o

root.pairsToObj = (pairs) -> pairFold {}, pairs
