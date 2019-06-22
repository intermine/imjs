nock = require 'nock'
path = require 'path'
fs   = require 'fs'

TESTMODEL_URL_VAR = 'TESTMODEL_URL'
root = process.env[TESTMODEL_URL_VAR]

RESPONSE_FOLDER = 'responses'

# Helper function to record the nock responses and store them
recordResponses = (fileName, before, after) ->
    before ->
        nock.recorder.rec
            output_objects: true
    
    after ->
        nock.restore()
        nockCallObjects = nock.recorder.play()
        fs.writeFile fileName, JSON.stringify(nockCallObjects), console.error


nockTest = ->
    nock 'http://localhost:8080/intermine-demo'
        .get '/service/model'
        .replyWithFile 200, path.join __dirname, 'responses/service-model.xml'

module.exports =
    nockTest: nockTest
    recordResponses: recordResponses