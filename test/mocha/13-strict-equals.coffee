Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{bothTests} = require './lib/segregation'
{setupMock} = require './lib/mock'

bothTests() && describe 'Equality', ->

  {service} = new Fixture()

  describe 'Case insensitivity', ->

    @beforeAll prepare ->
      setupMock '/service/summaryfields?format=json', 'GET'
      setupMock '/service/model?format=json', 'GET'
      setupMock '/service/version?format=json', 'GET'
      setupMock '/service/query/results', 'POST', '13-strict-equals.1'
      setupMock '/service/user/preferences', 'POST', '13-strict-equals.1'
      service.count select: ['Employee.*'], where: {name: {'=': 'brenda'}}
    
    it 'should find something', eventually (c) -> c.should.equal 1

  describe 'Case sensitivity', ->

    @beforeAll prepare ->
      setupMock '/service/summaryfields?format=json', 'GET'
      setupMock '/service/model?format=json', 'GET'
      setupMock '/service/version?format=json', 'GET'
      setupMock '/service/query/results', 'POST', '13-strict-equals.2'
      setupMock '/service/user/preferences', 'POST', '13-strict-equals.1'
      service.count select: ['Employee.*'], where: {name: {'==': 'brenda'}}

    it 'should find something', eventually (c) -> c.should.equal 0
