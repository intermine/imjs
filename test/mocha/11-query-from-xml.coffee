
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

  describe 'attempting to parse nonsense', ->
    attempt = -> Query.fromXML 'foo bar baz'

    it 'should raise an error', ->
      attempt.should.throwError /Invalid/

  describe 'attempting to parse things that cause xmldom#40', ->
    attempt = -> Query.fromXML '<r'

    it 'should raise an error, and not enter an infinite loop', ->
      attempt.should.throwError()

  describe 'attempting to parse non-strings', ->
    attempt = -> Query.fromXML new Object

    it 'should raise an error', ->
      attempt.should.throwError /Expected/

  describe 'attempting to parse an empty string', ->
    attempt = -> Query.fromXML ''

    it 'should raise an error', ->
      attempt.should.throwError /Expected/

  describe 'attempting to parse a blank string', ->
    attempt = -> Query.fromXML '   '

    it 'should raise an error', ->
      attempt.should.throwError /empty/

  describe 'the result of parsing sensible input', ->

    q = Query.fromXML xml

    it 'should have two elements in the view', ->
      q.view.length.should.equal 2

    it 'should have the right sort-order', ->
      q.sortOrder[0][0].should.equal 'Employee.name'
      q.sortOrder[1][0].should.equal 'Employee.fullTime'

      q.sortOrder[0][1].should.equal 'ASC'
      q.sortOrder[1][1].should.equal 'DESC'

    it 'should have a sub-class constraint', ->
      q.constraints[0].should.eql {path: 'Employee.department.manager', type: 'CEO'}

    it 'should have the expected attribute constraint', ->
      q.constraints[1].should.eql {path: "Employee.department.name", op: "=", value: "Sales"}

    it 'should have a constraint with the expected values', ->
      q.constraints[2].values.should.eql ['Foo', 'Bar', 'Baz']

    it 'should have three constraints', ->
      q.constraints.length.should.equal 3

    describe 'using this to instantiate a query', ->

      query = new Query(q)

      it 'should construct a query with the right sort-order', ->
        query.sortOrder[0].path.should.equal 'Employee.name'
        query.sortOrder[1].path.should.equal 'Employee.fullTime'

        query.sortOrder[0].direction.should.equal 'ASC'
        query.sortOrder[1].direction.should.equal 'DESC'
  
