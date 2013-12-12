'use strict';

var imjs, repl, utils;

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
repl.context.testmodel = imjs.Service.connect({
  root: "localhost:8080/intermine-test",
  token: "test-user-token"
});

require('repl.history')(repl, __dirname + '/.repl-history');
