IS_NODE = typeof exports isnt 'undefined'

if IS_NODE
  {DOMParser} = require('xmldom')
  __root__    = exports
  domParser   = new DOMParser
  parse       = (xml) -> # fn which is api compatible with jq behaviour
    xml = xml + '>' unless xml?.match('<.*>') # Otherwise we enter an infinite loop. srsly
    try
      ret = domParser.parseFromString(xml, 'text/xml') if xml
    catch e
      ret = undefined
    if (not ret) or (not ret.documentElement) or (ret.getElementsByTagName('parsererror').length)
      throw new Error('Invalid xml: '  + xml)
    return ret
else
  {jQuery, intermine} = this
  __root__ = (intermine.xml ?= {})
  parse = jQuery.parseXML

__root__.parse = parse

