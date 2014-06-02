{Service} = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
should = require 'should'

shouldHaveFailed = (done) -> (o) -> done new Error("Expected failure, got #{ o }")

describe 'parse failure', ->

  # An intentionally mis-configured service
  # Currently using mockable for some of this - may need changing in the future.
  service = Service.connect root: 'http://cdn.intermine.org/mox/intermine/testmodel/xml'

  describe 'Attempt to fetch the Model', ->

    promise = service.fetchModel()

    it 'should fail', (done) ->
      promise.then (shouldHaveFailed done), (-> done())

    it 'should provide a reasonable message', (done) ->
      promise.then (shouldHaveFailed done), (err) ->
        try
          String(err).should.containEql service.root
          done()
        catch e
          done e

describe 'not available failure', ->

  # An intentionally mis-configured service
  service = Service.connect root: 'http://www.metabolicmine2.org/the/return/of/meta'

  describe 'Attempt to fetch the Model', ->

    promise = service.fetchModel()

    it 'should fail', (done) ->
      promise.then (shouldHaveFailed done), (-> done())

    it 'should provide a reasonable message', (done) ->
      promise.then (shouldHaveFailed done), (err) ->
        try
          String(err).should.containEql service.root
          done()
        catch e
          done e
