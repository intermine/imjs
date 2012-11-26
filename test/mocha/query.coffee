{Query} = require '../../src/query'
{get} = require '../../src/util'

options =
    intermine:
        view: ["Employee.name", "Employee.age", "Employee.department.name"]
        constraints: [
            {path: "Employee.department.name", op: '=', value: "Sales*"},
            {path: "Employee.age", op: ">", value: "50"}
        ]
    sqlish:
        from: "Employee"
        select: ["name", "age", "department.name"]
        where:
            'department.name': 'Sales*'
            'age': {gt: 50}

describe 'Query', ->

    describe 'new', ->

        it 'should make a new query', ->
            q = new Query()
            q.should.be.an.instanceOf Query

        it 'should set the root based on the "root" option', ->
            q = new Query root: 'Gene'
            q.root.should.equal 'Gene'

        it 'should set the root based on the "from" option', ->
            q = new Query from: 'Gene'
            q.root.should.equal 'Gene'
    
    for k, v of options then do (k, v) ->

        describe "handles #{ k } options", ->

            q = new Query v

            it 'can interpret views', ->
                q.views.should.eql options.intermine.view

            it 'can derive root', ->
                q.root.should.eql('Employee')

            it 'can interpret constraints', ->
                cs = q.constraints
                cs.should.have.lengthOf(2)
                cs.map(get 'op').should.eql(['=', '>'])
                cs.map(get 'path').should.eql(['Employee.department.name', 'Employee.age'])

    describe 'Query syntaxes', ->

        qtrad = new Query options.intermine
        qsqlish = new Query options.sqlish

        it 'should be synonymous', -> qtrad.toXML().should.equal(qsqlish.toXML())

    describe '#clone()', ->

        orig = new Query from: 'Employee', select: ['name']

        it 'should produce unconnected clones', ->
            clone = orig.clone()
            clone.addToSelect 'age'
            orig.views.should.have.lengthOf 1
            clone.views.should.have.lengthOf 2

        it 'cloning should not include events by default', ->
            y = n = 0
            orig.on 'test:event', -> y++
            clone = orig.clone()
            clone.on 'test:event', -> n++
            orig.trigger 'test:event'
            y.should.equal 1
            n.should.equal 0


