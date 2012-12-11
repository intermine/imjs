Fixture = require './lib/fixture'
{eventually, prepare, always} = require './lib/utils'

describe 'Query', ->

    expected_views = [
        'Employee.name',
        'Employee.department.name',
        'Employee.department.manager.name',
        'Employee.department.company.name',
        'Employee.fullTime',
        'Employee.address.address'
    ]

    double_star = [
        'Employee.name',
        'Employee.department.name',
        'Employee.department.manager.name',
        'Employee.department.company.name',
        'Employee.fullTime',
        'Employee.address.address',
        'Employee.age',
        'Employee.end',
        'Employee.id'
    ]

    {service} = new Fixture()

    describe "#select(['*'])", ->

        @beforeEach prepare -> service.query root: 'Employee'

        it 'should expand stars to the summary fields', eventually (q) ->
            q.select ['*']
            q.views.should.eql expected_views

        it 'should expand double stars to all fields', eventually (q) ->
            q.select ['**']
            q.views.should.eql double_star


