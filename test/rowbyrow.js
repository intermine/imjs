var IM = require('../lib/service');

var flymine = new IM.Service({root: 'www.flymine.org/query'});

var query = {from: 'Gene', select: ['*'], where: {symbol: ['eve', 'zen', 'bib', 'r', 'h']}};
var largeQuery = {from: 'Gene', select: ['*'], where: {length: {lt: 1000}}};

var errorHandler = function(err, text) {console.error(err, '>>>' + text + '<<<');};

// This is required to test handling of chunk boundaries.
flymine.query(largeQuery, function(q) {
    var count = 0;
    var counter = q.recordByRecord([
        function(gene) {
            count++;
            //console.log("GENE: ", gene.symbol);
        },
        errorHandler
    ]);
    counter.on('end', function() {console.log('Count from loop: ' + count)});
    q.count(function(c) {
       console.log('Count from query: ' + c);
    });
});


flymine.query(query, function(q) {
    q.rowByRow([
        function(row) {
            console.log("ROW: ", row);
        },
        errorHandler
    ]);
});

flymine.query(query, function(q) {
    q.recordByRecord([
        function(gene) {
            console.log("GENE: ", gene.symbol);
        },
        errorHandler
    ]);
});


