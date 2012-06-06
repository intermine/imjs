{asyncTest, older_emps} = require './lib/service-setup'
{fold, AND}  = require '../../src/shiv'

exports['quick search:all'] = asyncTest 2, (beforeExit, assert) ->
    @service.search (rs, facets) =>
        @runTest () -> assert.ok rs.length >= 100, "Expected lots of rs, got #{ rs.length }"
        @runTest () -> assert.eql 5, facets.Category.Bank, "There are #{facets.Category.Bank} banks"

exports['quick search:term'] = asyncTest 1, (beforeExit, assert) ->
    @service.search 'david', (rs) => @runTest () -> assert.eql 2, rs.length

exports['quick search:facets'] = asyncTest 2, (beforeExit, assert) ->
    @service.search facets: {Category: 'Manager'}, (rs) =>
        @runTest () -> assert.eql rs.length, 24, "Got #{ rs.length } results"
        @runTest () -> assert.ok fold(true, AND) rs.map (l) -> l.type is 'Manager'

exports['quick search:limit'] = asyncTest 1, (beforeExit, assert) ->
    @service.search facets: {Category: 'Manager'}, size: 10, (rs) =>
        @runTest () -> assert.eql 10, rs.length, "Got #{ rs.length } results"

