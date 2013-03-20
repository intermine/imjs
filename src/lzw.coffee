IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

if IS_NODE
  intermine   = __root__
else
  {intermine} = __root__
  intermine = __root__.intermine = {} unless intermine?

intermine.compression ?= {}

intermine.compression.LZW =

  encode: (s) ->
    dict = {}
    data = (s + "").split("")
    out = []
    currChar
    phrase = data[0]
    code = 256
    for currChar in data
      currChar=data[i]
      if dict[phrase + currChar]?
        phrase += currChar
      else
        out.push if phrase.length > 1 then dict[phrase] else phrase.charCodeAt(0)
        dict[phrase + currChar] = code
        code++
        phrase = currChar

    out.push if phrase.length > 1 then dict[phrase] else phrase.charCodeAt(0)
    mapped = (String.fromCharCode(o) for o in out)
    return mapped.join("")

  decode: (s) ->
    dict = {}
    data = (s + "").split("")
    currChar = data[0]
    oldPhrase = currChar
    out = [currChar]
    code = 256
    phrase
    for currCode in data
      currCode = data[i].charCodeAt(0)
      if (currCode < 256)
        phrase = data[i]
      else
        phrase = if dict[currCode] then dict[currCode] else (oldPhrase + currChar)
      out.push(phrase)
      currChar = phrase.charAt(0)
      dict[code] = oldPhrase + currChar
      code++
      oldPhrase = phrase

    return out.join("")

