# 'Sharper than a shim.'
#
# This module exists to ensure that certain things we expect
# to exist really do. The signatures for these functions are the
# same as in the CommonJS specification, and modern VMs will
# not be patched.
#
# This module does not need to be executed when running in node.js,
# so don't feel obliged to require it.

HAS_CONSOLE = typeof console isnt 'undefined'
HAS_JSON = typeof JSON isnt 'undefined'
NOT_ENUM = [
  'toString',
  'toLocaleString',
  'valueOf',
  'hasOwnProperty',
  'isPrototypeOf',
  'propertyIsEnumerable',
  'constructor'
]

unless HAS_JSON
  # Try and fix this broken browser.
  script = document.createElement 'script'
  script.src = 'http://cdn.intermine.org/js/json3/3.2.2/json3.min.js'
  script.type = 'text/javascript'
  head = document.getElementsByTagName('head')[0] # document.head is broken in ie9
  head.appendChild script

unless Object.keys?
  hasOwnProperty = Object.prototype.hasOwnProperty
  hasDontEnumBug = not {toString:null}.propertyIsEnumerable "toString"

  Object.keys = (o) ->
    if (typeof o isnt "object" && typeof o isnt "" || o is null)
      throw new TypeError("Object.keys called on a non-object")

    keys = (name for name of o when hasOwnProperty.call(o, name))
    
    if hasDontEnumBug
      keys.push(nonEnum) for nonEnum in NOT_ENUM when hasOwnProperty.call(o, nonEnum)
    
    keys

unless Array::map?
  Array::map = (f) -> (f x for x in @)

unless Array::filter?
  Array::filter = (f) -> (x for x in @ when (f x))

unless Array::reduce?
  Array::reduce = (f, initValue) ->
    xs = @slice()
    ret = if arguments.length < 2 then xs.pop() else initValue
    ret = (f ret, x) for x in xs
    ret

unless Array::forEach?
  Array::forEach = (f, ctx) ->
    throw new Error("No function provided") unless f
    for x, i in @
      f.call((ctx ? @), x, i, @)

unless HAS_CONSOLE
  @console = {log: (->), error: (->), debug: (->)}
  window.console = @console if window?

console.log ?= ->
console.error ?= ->
console.debug ?= ->

unless console.log.apply? # Probably in IE here...
  console.log("Your console needs patching.")
  for m in ['log', 'error', 'debug'] then do (m) ->
    oldM = console[m]
    console[m] = (args) -> oldM(args)
