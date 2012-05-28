IMJS
====

InterMine Web-Services Communication Client Library

SYNOPSIS
========

```javascript
  var IM = require('imjs');
  var flymine = new IM.Service({root: 'www.flymine.org/query'});
  var query = {from: 'Gene', select: ['*'], where: {symbol: 'eve'}};
  flymine.query(query, function(q) {
    q.rows(rows) {
        console.log(rows);
    });
  });
```

DESCRIPTION
===========

This library abstracts the functionality of InterMine's web service layer.
