# This module supplies the **Registry** class for the **im.js**
# web-service client.
#
# Registry is representation of connection to the intermine registry
# RESTful API which serves to store and browse all known instances
# of InterMine
#
# This library is designed to be compatible with both node.js
# and browsers.

utils = require './util'
http = require './http'

{withCB, get} = utils
{doReq, merge} = http

# Root of the registry service being used to access Intermine data
ROOT = "http://registry.intermine.org/service/"

# Different scopes of service instances
INSTANCES_PATH = "instances"

# The representation of a connection to an Intermine Registry
class Registry
  # Helper function to default to JSON format unless specified
  # @param [String] intended datatype to return if present
  #
  # @return [String] datatype if provided or fallbacks to json data
  
  getFormat: (intended = 'json') =>
    return intended

  # Default error handler function to provide error stream if present
  # or fallback to stdout
  # @param [Any] e Logs the parameter provided under error stream if present
  #   or under the logging stream
  errorHandler: (e) ->
    f = console.error ? console.log
    f e

  # Concatenates relative path with root and returns final path to call
  # @param [Array<String>] path declare the nested scopes from
  #   where to fetch the data
  # @return [String] Final scope relative to the root of the
  #  service from where to make the request
  makePath: (path = []) =>
    ROOT + path.join '/'

  # Helper function to make request, to be augmented further as need arises
  # @param [String] method The HTTP method to use (one of GET, POST, PUT, DELETE).
  # @param [String] path The path fragment of the endpoint to use. The service's root
  #   will be prepended to obtain the full URI.
  # @param [Object,Array] data The parameters to send to the service.
  # @param [(data) ->] cb A function that will be called on the results when received.
  #
  # @return [Promise<Object>] A promise to yield a response object along
  # with callback attatched if provided
  makeRequest: (method = 'GET', path = '', data = {}, cb = ->) ->

    if utils.isArray cb
      [cb, errBack] = cb
    if utils.isArray data
      data = utils.pairsToObj data

    errBack ?= @errorHandler
    data = utils.copy data
    dataType = @getFormat data.format

    unless http.supports method
      [data.method, method] = [method, http.getMethod(method)]

    opts =
      data: data
      dataType: dataType
      success: cb
      error: errBack
      type: method
      url: @makePath [INSTANCES_PATH]

    withCB cb, http.doReq.call this, opts

  # Fetches instances of all known registry information
  # @param [->] cb A function to be attatched to the returned promise
  # @return [Promise<Array<Object>>] A promise which gets the results
  fetchAllMines: (cb = ->) =>
    @makeRequest 'GET', INSTANCES_PATH, {}, cb


exports.Registry = Registry