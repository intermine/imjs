###
*  Base64 encode / decode
*  http://www.webtoolkit.info/
###

# Generally applicable base64 encoding so that we can be nicely
# platform independent (ie. support ie8).

keyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="

char = String.fromCharCode
keyChar = (idx) -> keyStr.charAt idx

utf8_encode = (string) ->
  string = string.replace(/\r\n/g,'\n')

  chars = for c, i in string
    code = string.charCodeAt i
    if code < 128
      c
    else if code < 2048
      char((code >> 6) | 192) + char((code & 63) | 128)
    else
      char((code >> 12) | 224) + char(((char >> 6) & 63) | 128) + char((code & 63) | 128)

  chars.join ''

# Encode a UTF-8 input string in base64
# @param [String] input The input string
# @return [String] A string encoded in base64
exports.encode = (input) ->
  output = ""
  i = 0
  input = utf8_encode(input)

  while i < input.length

    chr1 = input.charCodeAt(i++)
    chr2 = input.charCodeAt(i++)
    chr3 = input.charCodeAt(i++)

    enc1 = chr1 >> 2
    enc2 = ((chr1 & 3) << 4) | (chr2 >> 4)
    enc3 = ((chr2 & 15) << 2) | (chr3 >> 6)
    enc4 = chr3 & 63

    if isNaN chr2
      enc3 = enc4 = 64
    else if isNaN chr3
      enc4 = 64

    output += [enc1, enc2, enc3, enc4].map(keyChar).join('')

  return output
