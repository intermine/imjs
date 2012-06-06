{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can find by id'] = asyncTest 5, (beforeExit, assert) ->
    davidQ = select: ['id'], from: 'Employee', where: {name: 'David Brent'}
    s = @service
    s.query davidQ, (q) => q.rows (rows) => s.findById 'Employee', rows[0][0], (david) =>
        @runTest () -> assert.equal 'David Brent', david.name
        @runTest () -> assert.equal 'Sales', david.department.name
        @runTest () -> assert.equal 41, david.age
        @runTest () -> assert.equal false, david.fullTime
        @runTest () -> assert.equal 'Manager', david['class']

