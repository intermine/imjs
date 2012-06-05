{Query} = require '../../src/query'

# Normalise whitespace so that XML can be compared more easily.
normalise = (s) -> s.replace(/\s+/gm, ' ').replace(/>\s*</gm, '><')

expected = """
    <query model="testmodel"
       view="Employee.name Employee.age Employee.department.name Employee.address.address"
       sortOrder="Employee.age DESC"
       constraintLogic="A and (B or C) and (D or E)" >
       <join path="Employee.address" style="OUTER"/>
       <constraint path="Employee.department.manager" type="CEO" />
       <constraint path="Employee.name" op="=" value="David*" />
       <constraint path="Employee.end" op="IS NULL" />
       <constraint path="Employee.age" op="&gt;" value="50" />
       <constraint path="Employee.department.name" op="ONE OF">
         <value>Sales</value>
         <value>Accounting</value>
       </constraint>
       <constraint path="Employee.department" op="IN" value="Good Departments" />
    </query>
"""

exports['test escape XML entities where needed'] = (beforeExit, assert) ->
    q = new Query {
        select: ['name']
        from: 'Employee'
        where:
            name: {contains: '<'}
            'department.name': ['R & D', '>']
        model: {name: 'testmodel'}
    }

    exp = """
        <query model="testmodel" view="Employee.name" >
            <constraint path="Employee.name" op="CONTAINS" value="&lt;" />
            <constraint path="Employee.department.name" op="ONE OF">
                <value>R &amp; D</value>
                <value>&gt;</value>
            </constraint>
        </query>
    """
    got = normalise(q.toXML())
    exp = normalise(exp)
    # console.log got
    # console.log exp
    assert.eql got, exp


exports['test serialise complex query'] = (beforeExit, assert) ->
    q = new Query {
            select: ['name', 'age', 'department.name', 'address.address']
            from: 'Employee'
            joins: ['address']
            where: {
                'department.manager': {isa: 'CEO'}
                name: 'David*'
                end: null
                age: {gt: 50}
                'department.name': ['Sales', 'Accounting']
                'department': {in: 'Good Departments'}
            }
            orderBy: [{age: 'DESC'}]
            constraintLogic: 'A and (B or C) and (D or E)'
            model: {name: 'testmodel'}
        }
    got = normalise(q.toXML())
    exp = normalise(expected)
    # console.log got
    # console.log exp
    assert.eql got, exp
