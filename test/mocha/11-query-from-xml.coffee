
{TESTMODEL} = require './data/model'
Fixture = require './lib/fixture'
{Query, Model} = Fixture
{get} = Fixture.funcutils

xml = """
  <query view="Employee.name Employee.age" sortOrder="Employee.name ASC Employee.fullTime DESC">
    <constraint path="Employee.department.manager" type="CEO"/>
    <constraint path="Employee.department.name" op="=" value="Sales"/>
    <constraint path="Employee.name" op="IN">
      <value>Foo</value>
      <value>Bar</value>
      <value>Baz</value>
    </constraint>
  </query>
"""


describe 'Query.fromXML', ->

  q = Query.fromXML xml

  it 'should not loop forever when parsing pathological xml', ->
    (-> Query.fromXML '<r').should.throw

  it 'should raise errors at empty strings', ->
    (-> Query.fromXML '  ').should.throw

  it 'should have two elements in the view', ->

    q.view.length.should.equal 2

  it 'should have the right sort-order', ->

    q.sortOrder[0][0].should.equal 'Employee.name'
    q.sortOrder[1][0].should.equal 'Employee.fullTime'

    q.sortOrder[0][1].should.equal 'ASC'
    q.sortOrder[1][1].should.equal 'DESC'

  it 'should construct a query with the right sort-order', ->

    query = new Query(q)

    query.sortOrder[0].path.should.equal 'Employee.name'
    query.sortOrder[1].path.should.equal 'Employee.fullTime'

    query.sortOrder[0].direction.should.equal 'ASC'
    query.sortOrder[1].direction.should.equal 'DESC'

  it 'should have three constraints', ->

    q.constraints.length.should.equal 3

  it 'should have a sub-class constraint', ->

    q.constraints[0].should.eql {path: 'Employee.department.manager', type: 'CEO'}

  it 'should have the expected constraint', ->

    q.constraints[1].should.eql {path: "Employee.department.name", op: "=", value: "Sales"}

  it 'should have a constraint with the expected values', ->

    q.constraints[2].values.should.eql ['Foo', 'Bar', 'Baz']

  
