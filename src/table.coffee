# This module supplies the **Table** class for the **im.js**
# web-service client.
#
# Tables are representations of the descriptions of the data
# available within a single database table.
#
# This library is designed to be compatible with both node.js
# and browsers.

IS_NODE = typeof exports isnt 'undefined'

__root__ = exports ? (@intermine ?= {})

# Import from the appropriate place depending on whether we are in
# node.js or in the browser.
if IS_NODE
  {set} = require './util'
else
  {set} = @intermine.funcutils

# The properties we expect the tables to have.
properties = ['attributes', 'references', 'collections']

# A representation of a single database table. It includes information
# on the fields that this table stores, as well as the relationships
# between it and other tables, either as N->1 (references) or N->many (collections).
class Table

  # Constructor.
  # @param opts The configuration options
  # @option opts [String] name The name of this table
  # @option opts [Object<String,Object>] attributes The descriptions of the table's fields.
  # @option opts [Object<String,Object>] references The descriptions of the N->1 relationships.
  # @option opts [Object<String,Object>] attributes The descriptions of the N->X relationships.
  constructor: ({@name, @attributes, @references, @collections}) ->
    @fields = {}
    @__parents__ = arguments[0]['extends'] # avoiding js keywords

    for prop in properties
      (set @[prop]) @fields
    for refProp in properties[1..]
      (set @[refProp]) @fields
    c.isCollection = true for _, c of @collections

  # Stringification.
  #
  # Stringifies to a readable representation with table name and the names of all fields.
  toString: -> "[Table name=#{ @name }, fields=[#{ n for n, _ of @fields}]]"

  # Get the names of all the classes this class directly inherits from.
  #
  # @return [Array<String>] A copy of the direct inheritance list.
  parents: () -> (@__parents__ ? []).slice()

__root__.Table = Table

