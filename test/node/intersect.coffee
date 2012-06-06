{asyncTest, older_emps} = require './lib/service-setup'

exports['can perform a list intersection'] = asyncTest 3, (beforeExit, assert) ->
    ls = ['My-Favourite-Employees', 'some favs-some unknowns-some umlauts']
    @service.intersect name: 'created_in_js-intersect', lists: ls, tags: ['js', 'node'], (l) =>
        l.del().done(() => @runTest () -> assert.ok true)
               .fail(() => @runTest () -> assert.ok false)
               .always () =>
            @runTest () -> assert.eql 2, l.size
            @runTest () -> assert.ok l.hasTag 'js'

