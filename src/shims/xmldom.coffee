# Export the globally available DOMParser module.
exports.DOMParser = if global.DOMParser?
  global.DOMParser
else
  class FakeDomParser
    constructor: -> throw new Error("DOMParser is not available")

