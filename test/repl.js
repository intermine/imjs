'use strict';

var imjs, repl, utils;

console.log("This is a Node REPL with imjs preloaded. You can invoke imjs however you wish to test features.");
console.log("There is also a FlyMine service assigned to `service`.");

imjs  = require('../');
utils = require('../build/util');
repl  = require('repl').start({
  prompt: '> '
});

repl.context.print = console.log.bind(console, '> ');
repl.context.utils = utils;
repl.context.get = utils.get;
repl.context.invoke = utils.invoke;
repl.context.imjs = imjs;
repl.context.service = imjs.Service.connect({
  root: "https://www.flymine.org/flymine/service",
  token: "test-user-token"
});

repl.setupHistory(__dirname + '/.repl-history', function(err, repl) {
  if (err) throw err;
});
