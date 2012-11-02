{asyncTest, older_emps} = require './lib/service-setup'
{omap, fold}  = require '../../src/shiv'

exports['can perform a list union'] = asyncTest 3, (beforeExit, assert) ->
    ls = ['My-Favourite-Employees', 'Umlaut holders']
    new_name ='created_in_js-union'
    tags = ['js', 'node', 'testing']
    @service.merge {name: new_name, lists: ls, tags: tags}, (l) =>
        @runTest -> assert.eql l.size, 6
        @runTest -> assert.ok l.hasTag('js')
        l.del().then(@pass, @fail)

