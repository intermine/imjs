{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can perform a list diff'] = asyncTest 3, (beforeExit, assert) ->
    ls = ['The great unknowns', 'some favs-some unknowns-some umlauts']
    new_name = "created_in_js-diff"
    tags = ['js', 'node', 'testing']
    @service.diff {name: new_name, lists: ls, tags: tags}, (l) =>
        @runTest () -> assert.eql l.size, 4
        @runTest () -> assert.ok l.hasTag 'js'
        l.contents (xs) =>
            @runTest () -> assert.includes xs.map( (x) -> x.name ), 'Brenda'
            l.del().fail () => @runTest () -> assert.ok false

