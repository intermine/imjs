
    var intermine = new imjs.Service({
      root: 'https://yeastmine.yeastgenome.org/yeastmine'
    });
    var query = {
      "constraintLogic": "B and A",
      "from": "Gene",
      "select": [
        "primaryIdentifier",
        "secondaryIdentifier",
        "organism.shortName",
        "symbol",
        "name"
      ],
      "orderBy": [{
        "path": "primaryIdentifier",
        "direction": "ASC"
      }],
      "where": [{
          "path": "organism.shortName",
          "op": "=",
          "value": "S. cerevisiae",
          "code": "B"
        },
        {
          "path": "secondaryIdentifier",
          "op": "=",
          "value": "YGL163C",
          "code": "A"
        }
      ]
    };
    intermine.records(query).then(function(response) {
      console.log(response);
      //open your javascript console to see the response printed.
    });
