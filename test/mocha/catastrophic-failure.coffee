{Service} = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
should = require 'should'

shouldHaveFailed = (done) -> (o) -> done new Error("Expected failure, got #{ o }")

describe 'catastrophic failure', ->

  # An intentionally mis-configured service
  service = Service.connect root: 'http://www.metabolicmine.org/the/return/of/meta'

  describe 'Attempt to fetch the Model', ->

    promise = service.fetchModel()

    it 'should fail', (done) ->
      promise.then (shouldHaveFailed done), (-> done())

    it 'should provide a reasonable message', (done) ->
      promise.then (shouldHaveFailed done), (err) ->
        try
          String(err).should.contain service.root
          done()
        catch e
          done e
