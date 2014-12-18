# Snippet for re-exposing code in the browser under the intermine name.

require './shiv'
module.exports = imjs = require './service'
merge = imjs.utils.merge

expose = (name, thing) ->
  if 'function' is typeof define and define.amd
    define name, [], thing
  else
    global[name] = thing

expose 'imjs', imjs

if (typeof intermine is 'undefined')
  expose 'intermine', imjs
else
  expose 'intermine', merge(intermine, imjs)

