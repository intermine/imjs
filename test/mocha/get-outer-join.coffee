Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
should = require 'should'
{unitTests} = require './lib/segregation'
{setupMock} = require './lib/mock'

unitTests() && describe 'Query', ->

  describe '#getOuterJoin(path)', ->

    {service} = new Fixture()

    @beforeAll prepare ->
      setupMock '/service/summaryfields?format=json', 'GET'
      setupMock '/service/model?format=json', 'GET'
      setupMock '/service/version?format=json', 'GET'
      setupMock '/service/user/preferences', 'POST', 'get-outer-join.1'
      service.query
        select: ['name'],
        from: 'Employee'
        joins: [ 'department', 'department.manager' ]
      
    it 'should find the outer join of department', eventually (q) ->
      q.getOuterJoin('department').should.equal 'Employee.department'

    it 'should find the outer join of department.name', eventually (q) ->
      q.getOuterJoin('department.name').should.equal 'Employee.department'

    it 'should find the outer join of department.manager', eventually (q) ->
      q.getOuterJoin('department.manager').should.equal 'Employee.department.manager'

    it 'should find the outer join of department.manager.name', eventually (q) ->
      q.getOuterJoin('department.manager.name').should.equal 'Employee.department.manager'

    it 'should not find any outer join for address', eventually (q) ->
      should.not.exist q.getOuterJoin('address')

