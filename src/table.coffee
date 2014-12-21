# This module supplies the **Table** class for the **im.js**
# web-service client.
#
# Tables are representations of the descriptions of the data
# available within a single database table.
#
# This library is designed to be compatible with both node.js
# and browsers.

merge = (src, dest) -> dest[k] = v for k, v of src

Promise = require './promise'

# The properties we expect the tables to have.
properties = ['attributes', 'references', 'collections']

# A representation of a single database table. It includes information on the
# fields that this table stores, as well as the relationships between it and
# other tables, either as N->1 (references) or N->many (collections).
class exports.Table

  # Constructor.
  # @param opts The configuration options
  # @param model [Model] The model this table belongs to.
  # @option opts [String] name The name of this table
  # @option opts [Object<String,Object>] attributes The descriptions of the table's fields.
  # @option opts [Object<String,Object>] references The descriptions of the N->1 relationships.
  # @option opts [Object<String,Object>] attributes The descriptions of the N->X relationships.
  constructor: (opts, @model) ->
    {@name, @tags, @displayName, @attributes, @references, @collections} = opts
    @fields = {}
    @__parents__ = (opts['extends'] ? [])# avoiding js keywords

    for prop in properties
      throw new Error "Bad model data: missing #{ prop }" unless @[prop]?
      merge @[prop], @fields

    c.isCollection = true for _, c of @collections

  # Stringification.
  #
  # Stringifies to a readable representation with table name and the names of
  # all fields.
  toString: -> "[Table name=#{ @name }, fields=[#{ n for n, _ of @fields}]]"

  # Get the names of all the classes this class directly inherits from.
  #
  # @return [Array<String>] A copy of the direct inheritance list.
  parents: () -> (@__parents__ ? []).slice()

  # Get a human readable display name, as configured for this class.
  #
  # This is the same as `table.model.makePath(table.name).getDisplayName()`,
  # but you don't need to make sure you have access to the model.
  #
  # @return [Promise<String>] A promise to yield a display name.
  getDisplayName: => new Promise (resolve, reject) =>
    if @model?
      resolve @model.makePath(@name).getDisplayName()
    else
      reject new Error 'model not set - cannot make path'
