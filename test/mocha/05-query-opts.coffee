# Test that the two syntaxes of defining queries are equivalent.
Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'
{integrationTests} = require './lib/segregation'

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

# Integration test because the way of interpreting the query
# is to be done by the service itself, `imjs` just sends the request
integrationTests() && describe 'The equivalence of syntaxes', ->

  {service} = new Fixture()

  @beforeAll prepare -> Fixture.utils.parallel service.query(trad), service.query(sqlish)

  it 'should mean that both syntaxes produce the same XML', eventually ([q1, q2]) ->
    q1.toXML().should.equal q2.toXML()

