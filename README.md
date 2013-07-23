IMJS
====

InterMine Web-Services Communication Client Library

SYNOPSIS
========

<!-- Execute scripts in the synopsis with test/check-synopsis.sh -->
```javascript
// Find and print all the exons associated with eve in D. melanogaster

// If running in node.js, the following line will be necessary:
var intermine = require('imjs');

var flymine   = new intermine.Service({root: 'www.flymine.org/query'});
var query     = {
  from: 'Gene',
  select: [
    'exons.symbol',
    'chromosome.primaryIdentifier',
    'exons.chromosomeLocation.start',
    'exons.chromosomeLocation.end'
  ],
  where: {
    symbol: 'eve',
    organism: {lookup: 'D. melanogaster'}}
};

flymine.rows(query).then(function(rows) {
  console.log("No. of exons: " + rows.length);
  rows.forEach(function printRow(row) {
    console.log("[" + row[0] + "] " + row[1] + ":" + row[2] + ".." + row[3]);
  });
});
```

DESCRIPTION
===========

This library abstracts the functionality of InterMine's web service layer. It is meant for
those wishing to build in communication layers to intermine servers, build graphical widgets
on top of the webservice APIs, or perform client side scripting.

The purpose of this library is to expose a uniform interface to the web-service API for both
node.js and browser based programming, wrapping some of the minor unpleasantness of dealing with
raw HTTP requests, as well as the more major issue of dealing with the path-query format, which
is complex.

Functionality
--------------

 * Data Queries

   Users may make arbitrarily complex queries against an intermine data-warehouse. See the
   [Query] [3] class for more information.

 * List Management

   Users may authenticate to their accounts (through the use of web-service tokens) and then
   have full freedom to create, edit and delete lists they have access to. See the [List] [2] class 
   for more information.

 * Analysis

   Users may perform enrichment analysis over lists they have access to. See [Service#enrichment] [4]
   and [List#enrichment] [5] for more information.

 * Data Model Introspection

   The structure of the data available in the data model is available for instropection through
   the [Model] [1] class. This is particularly useful for constructing dynamic data-driven interfaces.

LICENCE
=======

All intermine code is free software released under the LGPL licence <http://www.gnu.org/copyleft/lesser.html>.
You are free to modify and redistribute this software.

The copyright is held by Alex Kalderimis <alex@intermine.org>.

SUPPORT
=======

For help with this library, or the use of intermine in general, please contact <dev@intermine.org>.


[1]: classes/Model.html
[2]: classes/List.html
[3]: classes/Query.html
[4]: classes/Service.html#enrichment-instance
[5]: classes/List.html#enrichment-instance
