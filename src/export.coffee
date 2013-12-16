# Snippet for exposing code in the browser.
#
if typeof imjs isnt 'undefined'

  merge = imjs.utils.merge

  expose = (name, thing) ->
    if 'function' is typeof define and define.amd
      define name, [], thing
    else
      window[name] = thing

  expose('imjs', imjs)

  if (typeof intermine is 'undefined')
    expose 'intermine', imjs
  else
    expose 'intermine', merge(intermine, imjs)

