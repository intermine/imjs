Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
{get, invoke} = Fixture.funcutils

describe 'Query', ->

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

    describe 'count', ->
      expected = 36

      @beforeAll prepare -> service.count query

      it "should find #{ expected } rows", eventually (c) ->
        c.should.equal expected

    describe 'results', ->

      allowed = query.where[0].values

      @beforeAll prepare -> service.records query

      it 'should only find employees in sales and accounting', eventually (emps) ->
        allowed.should.containEql e.department.name for e in emps

      it 'should find David', eventually (emps) ->
        emps.map(get 'name').should.containEql 'David Brent'

