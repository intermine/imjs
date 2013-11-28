try
  DOMParser = window.DOMParser
catch e
  {DOMParser} = require('xmldom')

exports.parse = (xml) ->
  if not xml or typeof xml isnt 'string'
    throw new Error("Expected a string - got #{ xml }")

  dom = try
    parser = new DOMParser()
    parser.parseFromString(xml, 'text/xml')

  if (not dom) or (not dom.documentElement) or dom.getElementsByTagName('parsererror').length
    throw new Error("Invalid XML: #{ xml }")

  return dom
