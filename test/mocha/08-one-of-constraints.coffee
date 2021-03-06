Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
{get, invoke} = Fixture.funcutils
{bothTests} = require './lib/segregation'
{setupBundle} = require './lib/mock'
path = require 'path'

bothTests() && describe 'Query', ->

  setupBundle '08-one-of-constraints.1.json'
  # This query was failing in the webapp.
  query =
    model: {"name":"testmodel"},
    select: ["Employee.name","Employee.age", "Employee.department.name"],
    where: [
      {
        path: "Employee.department.name",
        op: "ONE OF",
        code: "A",
        values:["Sales","Accounting"]
      }
    ]
  
  {service, olderEmployees} = new Fixture()

  describe 'one of constraints', ->

    # Tests the count functionality of `imjs` along with the response of the testmine
    describe 'count', ->
      expected = 36

      @beforeAll prepare ->
        service.count query

      it "should find #{ expected } rows", eventually (c) ->
        c.should.equal expected

    # Tests the records functionality of `imjs` along with the response of the testmine
    describe 'results', ->

      allowed = query.where[0].values

      @beforeAll prepare ->
        setupBundle '08-one-of-constraints.2.json'
        service.records query
      

      it 'should only find employees in sales and accounting', eventually (emps) ->
        allowed.should.containEql e.department.name for e in emps

      it 'should find David', eventually (emps) ->
        emps.map(get 'name').should.containEql 'David Brent'

