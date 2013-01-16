Fixture = require './lib/fixture'
{prepare, eventually} = require './lib/utils'

normalise = (s) -> s.replace(/\s+/gm, ' ').replace(/>\s*</gm, '><')

describe 'Relevance of joins', ->

  {service} = new Fixture()

  describe 'a query with irrelevant joins', ->

    @beforeAll prepare -> service.query
      select: ['name']
      from: 'Employee'
      joins: ['department']

    it 'should not include the irrelvant join in the output XML', eventually (q) ->
      expected = """<query model="testmodel" view="Employee.name" ></query>"""
      xml = normalise q.toXML()
      xml.should.equal expected

    it 'should still have those joins though', eventually (q) ->
      q.isOuterJoined('department').should.be.true

  describe 'a query with relevant joins', ->

    @beforeAll prepare -> service.query
      select: ['name', 'department.name']
      from: 'Employee'
      joins: ['department']

    it 'should not include the irrelvant join in the output XML', eventually (q) ->
      expected = normalise """
        <query model="testmodel" view="Employee.name Employee.department.name" >
          <join path="Employee.department" style="OUTER"/>
        </query>
      """
      xml = normalise q.toXML()
      xml.should.equal expected

    it 'should still have those joins though', eventually (q) ->
      q.isOuterJoined('department').should.be.true

