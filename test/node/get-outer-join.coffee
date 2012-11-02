{Query} = require '../../src/query'

exports['test Query#getOuterJoin'] = (beforeExit, assert) ->
    q = new Query root: 'Gene'
    q.addJoin('chromosomeLocation')
    q.addJoin('exons')
    q.addJoin('chromosomeLocation.locatedOn')
    assert.equal('Gene.chromosomeLocation', q.getOuterJoin('Gene.chromosomeLocation.feature.name'))
    assert.equal('Gene.chromosomeLocation.locatedOn', q.getOuterJoin('Gene.chromosomeLocation.locatedOn.name'))
