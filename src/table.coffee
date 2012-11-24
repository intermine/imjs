IS_NODE = typeof exports isnt 'undefined'

__root__ = exports ? (@intermine ?= {})

if IS_NODE
    {set} = require './util'
else
    {set} = @intermine.funcutils

properties = ['attributes', 'references', 'collections']

class Table

    constructor: ({@name, @attributes, @references, @collections}) ->
        @fields = {}
        @__parents__ = arguments[0]['extends'] # avoiding js keywords

        for prop in properties
            (set @[prop]) @fields
        for refProp in properties[1..]
            (set @[refProp]) @fields
        c.isCollection = true for _, c of @collections

    toString: -> "[Table name=#{ @name }]"

    parents: () -> (@__parents__ ? []).slice()

__root__.Table = Table

