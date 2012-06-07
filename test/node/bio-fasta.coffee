{Service} = require '../../lib/service'
{testCase, asyncTestCase} = require './lib/util'

test = asyncTestCase () ->
    s = new Service root: 'www.flymine.org/query'
    {service: s}

exports['can get fasta'] = test 1, (beforeExit, assert) ->
    @service.query from: 'Gene', select: ['*'], where: {symbol: ['eve', 'zen', 'r', 'bib']}, (q) =>
        q.getFASTA (fasta) => @runTest () -> assert.ok fasta.split('>').length >= 4

