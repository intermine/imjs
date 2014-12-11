# This module supplies the **PathInfo** class for the **im.js**
# web-service client.
#
# Paths are representations of elements within a query, such as
# an element in the select list or something with a constraint on it.
# They consiste of a root class, zero or more references, and an optional
# final attribute.
#
# This library is designed to be compatible with both node.js
# and browsers.

intermine       = exports
utils           = require('./util')

{withCB, concatMap, get, any, set, copy, success, error} = utils

# Cached display names.
NAMES = {}
# Cached path instances - so we can return the same object wherever possible.
PARSED = {}

# Produce a key suitable for indexing paths with.
makeKey = (model, path, subclasses) ->
  """#{model?.name}|#{model?.service?.root}|#{path}:#{ "#{ k }=#{ v }" for k, v of subclasses }"""

#
# A representation of the information contained in a path
# expression. This class exposes the metadata available for this
# path, and is aware of class constraints placed upon it.
#
class PathInfo

  # Constructor of PathInfo objects.
  # PathInfo objects are constructed by the model. You should not need to
  # call this constructor yourself.
  #
  # @param options The data used to construct this PathInfo object
  # @option options [Table] root The root of this path
  # @option options [Model] model the model this path belongs to
  # @option options [Array<Field>] model The descriptor for each non-root path segment
  # @option options [Array<Field>] descriptors The descriptor for each non-root path segment
  # @option options [Object<String, TableInfo>] subclasses The subclass mapping
  # @option options [String] displayName The display name to use in preference to fetching.
  # @option options [String] ident A key used to index this path.
  constructor: ({ @root, @model, @descriptors, @subclasses, @displayName, @ident}) ->
    @end = @descriptors[@descriptors.length - 1]
    @ident ?= makeKey(@model, @, @subclasses)

  # Whether or not this is a root path.
  # @return [boolean] Whether this is a root path (i.e. has no parent).
  isRoot: () => @descriptors.length is 0

  # Whether or not this is a leaf path.
  # @return [boolean] Whether this path represents a data value.
  isAttribute: () => @end? and not @end.referencedType?

  # Whether or not this path represents one or more objects (i.e. is not a leaf).
  # @return [boolean] Whether or not this path represents a class of objects.
  isClass: () => @isRoot() or @end.referencedType?

  # Whether or not this path is a reference field (could be collection).
  # @return [boolean] True if not root, and not a leaf.
  isReference: () => @end?.referencedType?

  # Whether or not this path refers to a collection.
  # @return [boolean] True if a reference which is a collection.
  isCollection: () => @end?.isCollection ? false

  # Whether or not any segment of this path refers to a collection.
  # @return [boolean] True if this path contains at least one collection.
  containsCollection: () => any @descriptors, (x) -> x.isCollection

  # Get the Table object for this path (if root or reference, null if leaf).
  # @return [Table] description of the class this path represents.
  getEndClass: () => (@model.classes[@subclasses[@toString()] or @end?.referencedType]) or @root

  # Get the parent of this path. i.e., for `Gene.proteins.name` returns `Gene.proteins`
  #
  #   exonSymbols = model.makePath('Gene.exons.symbol')
  #   exons = model.makePath('Gene.exons')
  #   exons.equals(exonSymbols.getParent()) //=> true
  #
  # @return [PathInfo] The parent of this path.
  # @throws [Error] if this path has not parent.
  getParent: () =>
    if @isRoot()
      throw new Error("Root paths do not have parents")
    data =
      root: @root
      model: @model
      descriptors: @descriptors.slice(0, @descriptors.length - 1)
      subclasses: @subclasses
    return new PathInfo(data)

  # Adds a segment to this path. The segment must conform with the data model.
  # @param [String|Field] attr The field to add.
  # @return [PathInfo] a new PathInfo object with the appended segment.
  append: (attr) =>
    if @isAttribute()
      throw new Error("#{ this } is an attribute.")
    fld = if (typeof attr is 'string') then @getType().fields[attr] else attr
    unless fld?
      throw new Error("#{ attr } is not a field of #{ @getType() }")
    data =
      root: @root
      model: @model
      descriptors: @descriptors.concat([fld])
      subclasses: @subclasses
    return new PathInfo(data)

  # Analyses the inheritance hierarchy to determine if this path represents
  # an instance of the provided class. eg:
  #
  #   path = model.makePath('Gene.proteins')
  #   path.isa('Protein') //=> true
  #   path.isa('BioEntity') //=> true
  #   path.isa('Organism') //=> false
  #   path.append('name').isa('String') //=> true
  #
  # @param [String|Table] The purported parent class.
  # @return [boolean] If the path represents the provided class or one of its subclasses
  isa: (clazz) =>
    if @isAttribute()
      @getType() is clazz
    else
      name = if (clazz.name) then clazz.name else '' + clazz
      type = @getType()
      (name is type.name) or (name in @model.getAncestorsOf(type))

  # Fetches the configured display name for this path from the server.
  # @param [Function<Error, String, void>] cb An optional callback.
  # @return [Promise<String>] A promise for the display name.
  getDisplayName: (cb) =>
    if custom = @displayName
      return success custom
    @namePromise ?=
      if cached = NAMES[@ident]
        success cached
      else if @isRoot() and @root.displayName
        success @root.displayName
      else if not @model.service?
        error "No service"
      else
        path = 'model' + (concatMap (d) -> '/' + d.name) @allDescriptors()
        params = (set format: 'json') copy @subclasses
        @model.service.get(path, params).then(get 'display').then (n) => NAMES[@ident] ?= n
    withCB cb, @namePromise

  # Gets all the sub-paths of this class. eg:
  #
  #  path = model.makePath('Gene')
  #  path.getChildNodes() //=> [PathInfo('Gene.name'), PathInfo('Gene.proteins')...]
  #
  # @return [Array<PathInfo>] The children of this path.
  getChildNodes: () => (@append(fld) for name, fld of (@getEndClass()?.fields or {}))

  # @return [Array<Descriptor>] the root and the segment descriptors in a single array.
  allDescriptors: => [@root].concat(@descriptors)

  # @return [String] The string representation of this path, the same as that passed
  #                  to {Model::makePath}
  toString: () -> @allDescriptors().map(get 'name').join('.')

  # Overriden equals.
  # @return [boolean] true if the other path and this path are the same.
  equals: (other) -> @ is other or (@ident and other?.ident is @ident)

  #
  # Get the type of this path. If the path represents a class or a reference,
  # the class itself is returned, otherwise the name of the attribute type is returned,
  # minus any "java.lang." prefix.
  #
  # @return [String|Table] A class-descriptor, or an attribute type name.
  #
  getType: () -> (@end?.type?.replace /java\.lang\./, '') or @getEndClass()

PathInfo::toPathString = PathInfo::toString

# Parse a string, or stringable thing, into a PathInfo object,
# given a model to describe the data model and a listing of the
# optional subclass constraints.
#
# @param [Model] model The data model to validate against.
# @param [#toString] The path to interpret.
# @subclasses [Object<String,String>] The subclass constraints to bear in mind. (Optional).
#
# @return [PathInfo] The path information for this path.
# @throws if this path is invalid.
PathInfo.parse = (model, path, subclasses = {}) ->
  ident = makeKey(model, path, subclasses)
  if cached = PARSED[ident]
    return cached
  parts       = (path + '').split '.'
  root  = cd  = model.classes[parts.shift()]
  keyPath     = root.name
  descriptors = for part in parts
    fld = cd?.fields[part] or (cd = model.classes[subclasses[keyPath]])?.fields[part]
    unless fld
      throw new Error "Could not find #{ part } in #{ cd } when parsing #{ path }"
    keyPath += ".#{ part }"
    cd = model.classes[fld.type || fld.referencedType]
    fld
  PARSED[ident] = new PathInfo {root, model, descriptors, subclasses, ident}

# Remove cached instances from memory. Could be useful in long lived instances.
PathInfo.flushCache = () ->
  PARSED = {}
  NAMES = {}

intermine.PathInfo = PathInfo
