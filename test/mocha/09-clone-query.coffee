{prepare, eventually, always, clear, report} = require './lib/utils'
Fixture = require './lib/fixture'
{unitTests} = require './lib/segregation'
{setupMock} = require './lib/mock'

# Tests the clone() function of the Query class
unitTests() && describe 'Query#clone', ->

  {service, youngerEmployees} = new Fixture()

  @beforeAll prepare ->
    setupMock '/service/summaryfields?format=json', 'GET'
    setupMock '/service/ids', 'POST', '09-clone-query.1'
    setupMock '/service/model?format=json', 'GET'
    setupMock '/service/model?format=json', 'GET'
    service.query(youngerEmployees).then (q) ->
      [q, q.clone().addToSelect('end')]

  it 'should have several views in q', eventually ([q, clone]) ->
    q.views.length.should.be.above 0

  it 'should have more views in clone', eventually ([q, clone]) ->
    clone.views.length.should.be.above q.views.length

# Tests the clone() and sortOrder function of the Query class
unitTests() && describe 'Query#clone sortOrder', ->

  {service, youngerEmployees} = new Fixture()

  # MOCK HERE
  @beforeAll prepare -> service.query(youngerEmployees).then (q) ->
    q.orderBy ['age']
    [q, q.clone().addOrSetSortOrder(path: 'age', direction: 'DESC')]

  it 'should exist on both', eventually ([q, clone]) ->
    q.sortOrder.length.should.eql clone.sortOrder.length

  it 'should not have linked the sort-order elements', eventually ([q, clone]) ->
    q.sortOrder[0].direction.should.not.eql clone.sortOrder[0].direction

