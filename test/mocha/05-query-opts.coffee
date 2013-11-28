# Test that the two syntaxes of defining queries are equivalent.
Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
Promise = require 'promise'

trad =
  view: ["Employee.name", "Employee.age", "Employee.department.name"]
  constraints: [
    {path: "Employee.department.name", op: '=', value: "Sales*"},
    {path: "Employee.age", op: ">", value: "50"}
  ]

sqlish =
  from: "Employee"
  select: ["name", "age", "department.name"]
  where:
    'department.name': 'Sales*'
    'age': {gt: 50}

describe 'The equivalence of syntaxes', ->

  {service} = new Fixture()

  @beforeAll prepare -> Promise.all [ service.query(trad), service.query(sqlish) ]

  it 'should mean that both syntaxes produce the same XML', eventually ([q1, q2]) ->
    q1.toXML().should.equal q2.toXML()

