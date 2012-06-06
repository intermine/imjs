var IM = require('../lib/service');
var flymine = new IM.Service({root: 'www.flymine.org/query'});

var query = {from: 'Gene', select: ['*'], where: {symbol: ['eve', 'zen', 'bib', 'r', 'h']}};
var largeQuery = {from: 'Gene', select: ['*'], where: {length: {lt: 1000}}};

flymine.query(query, function(q) {
    q.eachRow(function(row) {console.log("ROW: ", row);});
});

flymine.query(query, function(q) {
    q.eachRecord(function(gene) {console.log("GENE: ", gene.symbol);});
});

// Demonstration that we get every gene.
flymine.query(largeQuery, function(q) {
    var count = 0;
    q.eachRecord(function(gene) {count++;}).then(function(iter) {
        iter.done(function() {console.log('Count from loop: ' + count)});
    });
    q.count(function(c) {console.log('Count from query: ' + c)});
});

