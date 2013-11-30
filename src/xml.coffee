try
  DOMParser = window.DOMParser
catch e
  {DOMParser} = require('xmldom')

sanitize = (xml) ->
  xml = xml.replace /^\s*/g, ''
  xml = xml.replace /\s$/g, ''
  if xml.length is 0
    return xml
  else if xml[xml.length - 1] isnt '>'
    return xml + '>' # Prevent infinite loop.
  else
    return xml

exports.parse = (xml) ->
  if typeof xml isnt 'string'
    throw new Error("Expected a string - got #{ xml }")

  xml = sanitize xml

  throw new Error("Expected content - got empty string") unless xml

  dom = try
    parser = new DOMParser()
    parser.parseFromString(xml, 'text/xml')

  if (not dom) or (not dom.documentElement) or dom.getElementsByTagName('parsererror').length
    throw new Error("Invalid XML: #{ xml }")

  return dom
