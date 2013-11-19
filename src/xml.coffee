{DOMParser} = require('xmldom')
domParser   = new DOMParser

exports.parse = (xml) -> # fn which is api compatible with jq behaviour
  xml = xml + '>' unless xml?.match('<.*>') # Otherwise we enter an infinite loop. srsly
  try
    ret = domParser.parseFromString(xml, 'text/xml') if xml
  catch e
    ret = undefined
  if (not ret) or (not ret.documentElement) or (ret.getElementsByTagName('parsererror').length)
    throw new Error('Invalid xml: '  + xml)
  return ret
