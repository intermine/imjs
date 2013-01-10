IS_NODE = typeof exports isnt 'undefined'

if IS_NODE
  imjs = exports
else
  intermine = (@intermine ?= {})
  imjs = (intermine.imjs ?= {})

imjs.VERSION = "unknown"

if IS_NODE
  # We have to read the version ourself.
  fs = require 'fs'
  path = require 'path'
  if process.mainModule?
    # only works with coffeescript - but why?
    # TODO: make this work in plain node.
    data = fs.readFileSync path.join(__dirname, '..', 'package.json'), 'utf8'
    pkg = JSON.parse data
    imjs.VERSION = pkg.version
else
  # Value will be injected by the build system.
  imjs.VERSION = "<%= pkg.version %>"
