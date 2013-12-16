# Export functions defined here either onto the
# exports object (if we are in node) or onto the global
# intermine.funcutils namespace

Promise = require './promise'

root = exports

root.defer = ->
  deferred = {}
  deferred.promise = new Promise (resolve, reject) ->
    deferred.resolve = resolve
    deferred.reject = reject
  return deferred

encode = (x) -> encodeURIComponent String x

qsFromList = (pairs) ->
  (pair.map(encode).join('=') for pair in pairs).join('&')

# Serialize an object or array as a query string.
root.querystring = (obj) ->
  return '' unless obj
  if isArray obj
    pairs = obj.slice()
  else
    pairs = []
    for k, v of obj
      if isArray v
        subList = ([k, sv] for sv in v)
        pairs = pairs.concat subList
      else
        pairs.push [k, v]
  # Remove undefined values, and serialise.
  qsFromList (p for p in pairs when p[1]?)

# Simply because this is a whole load cleaner and less ugly than
# calls to `_.bind(f, null, arg1, arg2, ...)`.
# @param [->] f The function to curry.
# @param args the arguments to curry.
# @return a curried function.
root.curry = curry = (f, args...) -> (rest...) -> f.apply(null, args.concat(rest))

# Helper for transforming an error into a rejection.
# @param e The error.
# @return [Promise<Error>] A promise to reject with an error.
root.error = error = (e) -> new Promise (_, reject) -> reject new Error e

# Helper for wrapping a value in a promise.
# @param args the The resolution.
# @return [Promise<args...>] A promise to resolve with the resolution.
root.success = success = Promise.from

# Helper for performing promises in parallel. Mostly so we can
# change promise library as we see fit...
root.parallel = Promise.all

# Attach a node-style callback (err, result), yielding the original promise.
# @param f The callback
# @param p The promise
# @return [Promise] The promise
root.withCB = (fs..., p) ->
  for f in fs when f? then do (f) ->
    onSucc = (res) -> f null, res
    onErr = (err) -> f err
    p.then onSucc, onErr
  return p

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

root.take = (n) -> (xs) -> if n? then xs[0 .. n - 1] else xs.slice()

# Curried version of filtering
root.filter = (f) -> (xs) -> (x for x in xs when f x)

root.uniqBy = (f, xs) ->
  if arguments.length is 1
    return curry root.uniqBy, f
  keys = []
  values = []
  return values unless xs?
  for x in xs
    k = f x
    unless k in keys
      keys.push k
      values.push x
  values

root.find = (xs, f) ->
  if arguments.length is 1
    f = xs
    return (xs) -> root.find xs, f
  for x in xs
    return x if f x
  return null

# Test for arrayishness, either directly or by duck-typing
isArray = (Array.isArray ? (xs) -> xs?.splice? and xs?.push? and xs?.pop? and xs?.slice?)
root.isArray = isArray

root.isFunction = if (typeof /./ isnt 'function')
  (f) -> typeof f is 'function'
else
  (f) -> f? and f.call? and f.apply? and f.toString() is '[object Function]'

entities =
  '&': '&amp;'
  '<': '&lt;'
  '>': '&gt;'
  '"': '&quot;'
  "'": '&#x27;'

# XML escaping
root.escape = (str) ->
  return '' if not str?
  String(str).replace /[&<>"']/g, (entity) -> entities[entity]

# Until I can find a nicer name for this...
# Basically a mapping over an object, taking a
# function of the form (oldk, oldv) -> [newk, newv]
# with the addition of shallowly copying any values
# that are arrays.
root.omap = (f) ->
  merger = fold (a, oldk, oldv) ->
    [newk, newv] = f oldk, oldv
    newv = newv.slice() if isArray newv
    a[newk] = newv
    return a
  (xs) -> merger {}, xs

root.copy = root.omap (k, v) -> [k, v]

root.partition = (f) -> (xs) ->
  divide = fold ([trues, falses], x) ->
    if f x
      [trues.concat([x]), falses]
    else
      [trues, falses.concat([x])]
  divide [[], []], xs

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
    else if typeof ret is 'number'
      ret + fx
    else if ret.concat?
      ret.concat(fx)
    else
      merge ret, fx
  ret

root.map = (f) -> invoke 'map', f

comp = fold (f, g) -> (args...) -> f g args...

root.compose = (fs...) -> comp fs

root.flatMap = root.concatMap

root.difference = (xs, remove) -> (x for x in xs when x not in remove)

root.stringList = (x) -> if typeof x is 'string' then [x] else x

root.flatten = flatten = (xs...) ->
  ret = []
  for x in xs
    if isArray(x)
      for xx in flatten.apply(null, x)
        ret.push xx
    else
      ret.push x
  ret

root.sum = root.concatMap id

root.merge = merge = (objs...) ->
  newObj = {}
  for o in objs
    for own k, v of o
      newObj[k] = v
  return newObj

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
root.invoke = invoke = (name, args...) -> invokeWith name, args

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
root.invokeWith = invokeWith = (name, args = [], ctx = null) -> (o) ->
  if not o?
    throw new Error("""Cannot call method "#{ name }" of null""")
  if not o[name]
    throw new Error("""Cannot call undefined method "#{ name } of #{ o }""")
  else
    o[name].apply((ctx or o), args)

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

# Make a function that lets users know
# when they are trying to use a service that
# isn't supported by their current service.
REQUIRES = (required, got) ->
  "This service requires a service at version #{ required } or above. This one is at #{ got }"

# A wrapper for functions that make requests to endpoints
# that require a certain version of the intermine API.
root.REQUIRES_VERSION = (s, n, f) -> s.fetchVersion().then (v) ->
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

root.sequence = (fns...) -> thenFold success(), fns

pairFold = fold (o, [k, v]) ->
  if o[k]?
    throw new Error("Duplicate key: #{ k }")
  o[k] = v
  o

root.pairsToObj = (pairs) -> pairFold {}, pairs
