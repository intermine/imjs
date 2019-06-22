nock = require 'nock'
path = require 'path'
fs   = require 'fs'

TESTMODEL_URL_VAR = 'TESTMODEL_URL'
root = process.env[TESTMODEL_URL_VAR]
RESPONSE_FOLDER = 'responses'

nockTest = ->
    nock 'http://localhost:8080/intermine-demo'
        .get '/service/model'
        .replyWithFile 200, path.join __dirname, 'responses/service-model.xml'

module.exports =
    nockTest: nockTest