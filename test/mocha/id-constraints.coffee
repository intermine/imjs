Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'
{get, invoke} = Fixture.funcutils

# This query was failing in the webapp.
getQuery = (ids) -> query =
    model: {"name":"testmodel"},
    select: ["Employee.name","Employee.age", "Employee.department.name"],
    where: [{"path":"Employee","op":"IN","code":"A","ids":ids}]

describe 'Query', ->
    
    {service, olderEmployees} = new Fixture()

    describe 'ID constraints', ->

        @beforeAll prepare ->
            service.records(olderEmployees)
                   .then(invoke 'map', get 'objectId')
                   .then(getQuery)
                   .then(service.rows)

        it 'should fetch the 46 older employees', eventually (rows) ->
            rows.length.should.equal 46

        it 'should contain information about David', eventually (rows) ->
            rows.map(get 0).should.include 'Malcolm'


