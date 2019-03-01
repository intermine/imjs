var service = new imjs.Service({
  root: "https://yeastmine.yeastgenome.org/yeastmine"
});
var query = {
  "from": "Gene",
  //here we're selecting the name of the pathway and also
  //the primary and length id of the gene.
  "select": ["pathways.name", "primaryIdentifier", "length"],
  "model": {
    "name": "genomic"
  },
  "orderBy": [{
    "path": "pathways.name",
    "direction": "ASC"
  }]
};
var pathways = new imjs.Query(query, service),
  // when you're running a summary query you need to
  // choose a pathway to summarise. Here we choose length,
  // and the response from the server will be effectively
  // a histogram of *all* the lengths in this query.
  // What's a histogram? https://en.wikipedia.org/wiki/Histogram
  pathwaysPath = [query.from, query.select[2]].join('.'); //Gene.length
s
console.log("%cpathwaysPath", "color:turquoise;font-weight:bold;", pathwaysPath);
pathways.summarize(pathwaysPath).then(function(pathwaySummary) {
  console.log(pathwaySummary);
});
