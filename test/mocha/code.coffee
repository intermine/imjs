Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{bothTests} = require './lib/segregation'
{setupMock, setupBundle} = require './lib/mock'
nock = require 'nock'
path = require 'path'

# Tests both the query/code endpoint of the service, and the fetchCode function
bothTests() && describe 'Query', ->

  {service, allEmployees} = new Fixture()

  describe '#fetchCode', ->

    @beforeAll prepare ->
      setupMock '/service/user/preferences', 'POST', 'code.1'
      setupMock '/service/user/preferences', 'POST', 'code.1'
      setupMock '/service/user/preferences', 'POST', 'code.1'
      setupMock '/service/user/whoami', 'GET'
      # nock.load path.join __dirnsetupRecorder, stopRecorder, ame, '/lib/bundledResponses/code.1
      #.json'
      setupBundle 'code.1.json'
      service.query(allEmployees).then (q) -> q.fetchCode 'py'

    
    @afterAll ->
      # stopRecorder 'dummy.json'

    it 'should return some code', eventually (code) ->
      code.length.should.be.above 0

  describe '#fetchCode(long-uri)', ->

    values = [0 .. 2000]

    @beforeAll prepare ->
      setupMock '/service/user/preferences', 'POST', 'code.1'
      setupMock '/service/user/whoami', 'GET'
      # nock.load path.join __dirname, '/lib/bundledResponses/code.2.json'
      setupBundle 'code.2.json'
      service.query(allEmployees).then (q) ->
        q.addConstraint {path: 'age', op: 'ONE OF', values}
        q.fetchCode 'py'

    @afterAll ->
      # stopRecorder 'dummy2.json'

    it 'should return some code', eventually (code) ->
      code.length.should.be.above 1000



