{asyncTest} = require './lib/service-setup'
{omap}  = require '../../src/util'

# Normalise whitespace so that XML can be compared more easily.
normalise = (s) -> s.replace(/\s+/gm, ' ').replace(/>\s*</gm, '><')

query = select: ['name'], from: 'Employee', joins: ['department']

exports['test relevant join'] = asyncTest 1, (beforeExit, assert) ->
    expected = """<query model="testmodel" view="Employee.name" ></query>"""
    @service.query query, @testCB (q) -> assert.eql normalise(expected), normalise(q.toXML())

exports['test irrelevant join'] = asyncTest 1, (beforeExit, assert) ->
    q2 = omap((k, v) -> [k, if k is 'select' then v.concat(['department.name']) else v]) query
    expected = """<query model="testmodel" view="Employee.name Employee.department.name" >
        <join path="Employee.department" style="OUTER"/>
    </query>"""
    @service.query q2, @testCB (q) -> assert.eql normalise(expected), normalise(q.toXML())
