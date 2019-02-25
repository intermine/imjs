utils = require './util'
http = require './http'

{withCB, get} = utils
{doReq, merge} = http

ROOT = "http://registry.intermine.org/service/instances"

class Registry
  fetchAllMines: (cb = ->) =>
    opts = type: 'GET', url: ROOT, dataType: 'json'
    withCB cb, http.doReq opts


exports.Registry = Registry