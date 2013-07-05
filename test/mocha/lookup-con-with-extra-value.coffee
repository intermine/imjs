{TESTMODEL} = require './data/model'
Fixture = require './lib/fixture'
{Query, Model} = Fixture
{get} = Fixture.funcutils

options =
  intermine:
    view: ["Employee.name"]
    constraints: [
      {path: "Employee", op: "LOOKUP", value: "Bill", extraValue: "Sales"}
    ]

EXPECTED_XML = """<query model="testmodel" view="Employee.name" >""" +
  """<constraint path="Employee" op="LOOKUP" value="Bill" extraValue="Sales" />""" +
  """</query>"""

describe 'Query', ->

  describe 'lookup constraints with extra values', ->

    testmodel = new Model TESTMODEL.model

    q = new Query options.intermine
    q.model = testmodel

    it 'should serialize correctly', ->
      q.toXML().should.eql(EXPECTED_XML)

