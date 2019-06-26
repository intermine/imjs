Fixture              = require './lib/fixture'
{prepare, eventually, always} = require './lib/utils'
should               = require 'should'
{integrationTests, bothTests} = require './lib/segregation'
{setupRecorder, stopRecorder, setupBundle} = require './lib/mock'

SLOW = 200

there_is_one_and_it_is_vikram = (results) ->
  results.length.should.equal 1
  results[0].identifier.should.equal 'Vikram'

there_are_seven = (results) ->
  results.length.should.equal 7
  results[0].identifier.should.equal 'Vikram'

# Tests fetchWidgets and that widgets can be fetched
integrationTests() && describe 'Service', ->

  @slow SLOW
  {service, olderEmployees} = new Fixture()

  integrationTests() && describe '#fetchWidgets', ->

    @beforeAll prepare service.fetchWidgets

    it 'gets a list of the available widgets', eventually (widgets) ->
      should.exist widgets
      widgets.length.should.be.above 1
      (w for w in widgets when w.name is 'contractor_enrichment').length.should.equal 1

  integrationTests() && describe '#fetchWidgetMap', ->

    @beforeAll prepare service.fetchWidgetMap

    it 'gets a mapping from name to widget', eventually (widgets) ->
      should.exist widgets.contractor_enrichment
      widgets.contractor_enrichment.widgetType.should.equal 'enrichment'

  integrationTests() && describe '#enrichment', ->

    @beforeAll prepare -> service.enrichment
      list: 'My-Favourite-Employees'
      widget: 'contractor_enrichment'
      maxp: 1

    it 'performs an enrichment calculation', eventually there_is_one_and_it_is_vikram

  integrationTests() && describe '#enrichment, specifying correction', ->

    @beforeAll prepare -> service.enrichment
      list: 'My-Favourite-Employees'
      widget: 'contractor_enrichment'
      maxp: 1
      correction: 'Bonferroni'

    it 'performs an enrichment calculation', eventually there_are_seven

  integrationTests() && describe '#enrichment with callback', ->

    it 'performs an enrichment calculation with a callback', (done) ->
      opts =
        list: 'My-Favourite-Employees'
        widget: 'contractor_enrichment'
        maxp: 1
      service.enrichment opts, (err, results) ->
        return done(err) if err?
        try
          there_is_one_and_it_is_vikram results
          done()
        catch e
          done e
      return undefined

# Tests for the enrichment function of the query object
# and the widget in the service too
integrationTests() && describe 'Query', ->

  @slow SLOW
  {service, olderEmployees} = new Fixture()

  describe '#enrichment', ->

    @beforeAll prepare -> service.fetchList('My-Favourite-Employees').then (l) -> l.enrichment
      widget: 'contractor_enrichment'
      maxp: 1

    it 'performs an enrichment calculation', eventually there_is_one_and_it_is_vikram

