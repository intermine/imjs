IS_NODE = typeof exports isnt 'undefined'

if IS_NODE
    constants = exports
else
    intermine = (@intermine ?= {})
    constants = (intermine.constants ?= {})

# The Accept headers that correspond to each data-type.
constants.ACCEPT_HEADER =
    "json": "application/json",
    "jsonobjects": "application/json;type=objects",
    "jsontable": "application/json;type=table",
    "jsonrows": "application/json;type=rows",
    "jsoncount": "application/json;type=count",
    "jsonp": "application/javascript",
    "jsonpobjects": "application/javascript;type=objects",
    "jsonptable": "application/javascript;type=table",
    "jsonprows": "application/javascript;type=rows",
    "jsonpcount": "application/javascript;type=count"
