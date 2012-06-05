{Query} = require '../../src/query'

exports['test clones are unconnected'] = (beforeExit, assert) ->
    q = new Query from: 'Employee', select: ['name']
    c = q.clone()
    c.addToSelect 'age'
    assert.eql q.views, ['Employee.name']
    assert.eql c.views, ['Employee.name', 'Employee.age']

exports['test clones do not grab events'] = (beforeExit, assert) ->
    n = 0
    q = new Query()
    q.on 'test:event', () -> n++
    c = q.clone()
    c.on 'test:event', () ->
        n++
        assert.ok false, "Should not have run"
    q.trigger 'test:event'
    beforeExit () ->
        assert.equal 1, n
