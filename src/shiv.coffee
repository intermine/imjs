# 'Sharper than a shim.'
#
# This module exists to ensure that certain things we expect
# to exist really do. The signatures for these functions are the
# same as in the CommonJS specification, and modern VMs will
# not be patched.
#
# This module does not need to be executed when running in node.js,
# so don't feel obliged to require it.

IS_NODE = typeof exports isnt 'undefined'
HAS_CONSOLE = typeof console isnt 'undefined'

unless IS_NODE

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
    console = {log: (->), error: (->), debug: (->)}

  console.log ?= ->
  console.error ?= ->
  console.debug ?= ->

  unless console.log.apply? # Probably in IE here...
    for m in ['log', 'error', 'debug'] then do (m) ->
      oldM = console[m]
      console[m] = (args) -> oldM(args)
