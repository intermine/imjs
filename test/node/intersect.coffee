{clearTheWay, asyncTest, older_emps} = require './lib/service-setup'

args =
    lists: ['My-Favourite-Employees', 'some favs-some unknowns-some umlauts']
    tags: ['js', 'node']
    name: 'created_in_js-intersect'

exports['can perform a list intersection'] = asyncTest 3, (beforeExit, assert) ->
    clearTheWay(@service, args.name).then(=> @service.intersect args).then (l) =>
        @runTest -> assert.eql 2, l.size
        @runTest -> assert.ok l.hasTag 'js'
        l.del().done(@pass).fail(@fail)

