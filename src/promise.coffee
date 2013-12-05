Parent = require 'promise'

module.exports = Promise = (fn) ->
  unless @ instanceof Promise
    return new Promise fn
  Parent.call(@, fn)

Promise.prototype = Object.create(Parent.prototype)
Promise::constructor = Promise

Promise::fail = (onError) -> @then null, onError

# Inherit static API.
Promise.all = Parent.all
Promise.from = Parent.from
