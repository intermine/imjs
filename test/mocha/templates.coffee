Fixture              = require './lib/fixture'
should               = require 'should'
{prepare, eventually, always, shouldBeRejected} = require './lib/utils'

describe 'Fetching templates', ->

  {service} = new Fixture
  
  @beforeAll prepare service.fetchTemplates

  it 'should find some templates', eventually (templates) ->
    should.exist templates

  it 'should include ManagerLookup', eventually (templates) ->
    templates.should.have.property('ManagerLookup').with.property('select')

describe 'Using templates', ->

  {service} = new Fixture
  
  @beforeAll prepare service.fetchTemplates

  it 'should be just like using queries', eventually (templates) ->
    service.count(templates.ManagerLookup).then (c) -> c.should.equal 2

  it 'should be fine to adjust their values', eventually (templates) ->
    service.query(templates.ManagerLookup)
           .then((q) -> q.constraints[0].value = 'David Brent'; q.count())
           .then (c) -> c.should.equal 1
