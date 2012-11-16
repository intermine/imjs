{Query} = require '../../src/query'
{isArray} = require 'util'

exports['test clones are unconnected'] = (beforeExit, assert) ->
    q = new Query from: 'Employee', select: ['name']
    c = q.clone()
    c.addToSelect 'age'
    assert.eql 1, q.views.length
    assert.eql ['Employee.name'],                 q.views, "#{ q.views } should be Emp.(name)"
    assert.eql 2, c.views.length
    assert.eql ['Employee.name', 'Employee.age'], c.views

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
