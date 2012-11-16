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
        @superClasses = arguments[0]['extends'] # avoiding js keywords

        for prop in properties
            (set @[prop]) @fields
        for refProp in properties[1..]
            (set @[refProp]) @fields
        c.isCollection = true for _, c of @collections

    toString: -> "[Table name=#{ @name }]"

exports.Table = Table

