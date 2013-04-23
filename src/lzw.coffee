IS_NODE = typeof exports isnt 'undefined'
__root__ = exports ? this

if IS_NODE
  intermine   = __root__
else
  {intermine} = __root__
  intermine = __root__.intermine = {} unless intermine?

intermine.compression ?= {}

buildDict = (size) ->
  dict = {}
  for i in [0 .. size]
    dict[String.fromCharCode i] = i
  dict

buildArray = (size) -> (String.fromCharCode x for x in [0 .. size])


intermine.compression.LZW =

  encode: (s) ->
    data = (s + "").split("")
    out = []
    phrase = ''
    dictSize = 256
    dict = buildDict dictSize

    for char in data
      currPhrase = phrase + char
      if currPhrase of dict
        phrase = currPhrase
      else
        out.push dict[phrase]
        dict[currPhrase] = dictSize++
        phrase = String(char)

    if phrase isnt ''
      out.push dict[phrase]

    return out

  decode: (data) ->
    dictSize = 256
    dict = buildArray dictSize
    entry = ''
    [head, tail...] = data
    word = String.fromCharCode(head)
    result = [word]

    for code in tail
      entry = if dict[code]
        dict[code]
      else if code is dictSize
        word + word.charAt(0)
      else
        throw new Error("Key is #{ code }")

      result.push entry

      dict[dictSize++] = word + entry.charAt(0)
      word = entry

    result.join('')

